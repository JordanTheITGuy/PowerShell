<#
.SYNOPSIS
    This script uses presumed information about an environment to create a deployment schedule for pilot or Production. The script assumes some 
    specific pieces about the users environment including that certain naming conventions will be followed. These naming conventions are based around
    the following for SUGS:
    ADR - SERVER - 
    ADR - WORKSTATIONS - 
    ADR - Ancillary -

    And the following for collections:
    SUM - Servers
    SUM - Workstations

    This can be modified by simply editing those locations in the scripts. Currently the script deploys patches to five groups over 5 days.
    Alternatively you can use the Pilot switch to deploy the patches to pilot or Production. 


.DESCRIPTION
    This script is designed to supplement the method of using ADR's for deploying them to a place hoder collection. With the potential negative
    impact of patches from Microsoft its easier to deploy patches using ADR's to empty place holder collectiosn and then script their deployment instead.
    This script allows an example of that. 

.PARAMETER Param
    This allows the use of two parameters
    - Pilot: - Deploys the - Pilot collection memberships as needed
    - Production: - Deploys all of the patches to the Production collections based on a well established production schedule.

.EXAMPLE
    Example of running the script:
        .\Create-Deployments.PS1 -Pilot (Runs the pilot install)
        .\Create-Deployments.PS1 -Production (Runs the production installs)

.NOTES
    FileName:    Create-Deplyments.ps1
    Author:      Jordan Benzing
    Contact:     @JordanTheItGuy
    Created:     2018-12-14
    Updated:     2018-12-14

    MIT - License:
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version history:
    1.0.0 - (2018-12-14) Script created
    1.0.1 - (2018-12-17) Production Version Ready - Added All required Switches
    1.0.2 - (2018-12-17) Production Version Ready - Tested and added in clean up logic to remove all deployments created by this script older than 25 days.
    1.0.3 - (2019-01-07) Production Version Ready - Tested and added in clean up logic to remove all Old software Update groups that are older than 60 days.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$false, HelpMessage="Creates ONLY the Pilot deployments.")]
    [switch]$Pilot,
    [parameter(Mandatory=$false, HelpMessage="Creates ONLY the Production deployments.")]
    [switch]$Production
)

############################################
#region Calculations

function Get-StartDate {
    #Fucntion for calculating when to start the patching process based on finding patch tuesday.
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, HelpMessage="Param description.")]
        [int]$PatchingOffset
    )
    try
    {
        Write-log -LogLevel 1 -Message "Calculating the start date for patching"
        Write-Verbose -Message "Calculating start date for patching" -Verbose
        $CurrentMonth = (Get-Date).Month
        #This section starts by collecting the second tuesday of the month. Math is performed by finding the current month, then getting the first
        #Day of the month. Once the first day of the month is found we move on to calculate when the second tuesday is based on what day of the week
        #the first day of the month is. 
            switch ($(Get-Date -Month $CurrentMonth -Day 1).DayOfWeek) {
                Sunday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(9)}
                Monday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(8)}
                Tuesday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(7)}
                Wednesday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(13)}
                Thursday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(12)}
                Friday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(11)}
                Saturday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(10)}
            }
            $Startdate = $SecondTuesday.AddDays($PatchingOffset)
            #Once the Second Tuesday of the month is calcualted then above we add in the patching offset from patch tuesday. 
            Write-Log -LogLevel 1 -Message "Determined the start date to be $($Startdate)"
            Write-Verbose -Message "Determined the start date to be $($Startdate)" -Verbose
            return $Startdate
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}

#endregion Calculations
############################################

############################################
#region HelperFunctions
function Get-CMModule
#This application gets the configMgr module
{
    [CmdletBinding()]
    param()
    Try
    {
        Write-Verbose "Attempting to import SCCM Module"
        #Retrieves the fcnction from ConfigMgr installation path. 
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        Write-Verbose "Succesfully imported the SCCM Module"
    }
    Catch
    {
        Throw "Failure to import SCCM Cmdlets."
    } 
}

function Test-ConfigMgrAvailable
#Tests if ConfigMgr is availble so that the SMSProvider and configmgr cmdlets can help. 
{
    [CMdletbinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [bool]$Remediate
    )
        try
        {
            if((Test-Module -ModuleName ConfigurationManager -Remediate:$true) -eq $false)
            #Checks to see if the Configuration Manager module is loaded or not and then since the remediate flag is set automatically imports it.
            { 
                throw "You have not loaded the configuration manager module please load the appropriate module and try again."
                #Throws this error if even after the remediation or if the remediation fails. 
            }
            write-Verbose "ConfigurationManager Module is loaded"
            Write-Verbose "Checking if current drive is a CMDrive"
            if((Get-location).Path -ne (Get-location -PSProvider 'CmSite').Path)
            #Checks if the current location is the - PS provider for the CMSite server. 
            {
                if($Remediate)
                #If the remediation field is set then it attempts to set the current location of the path to the CMSite server path. 
                    {
                        Set-Location -Path (((Get-PSDrive -PSProvider CMSite).Name) + ":")
                        #Sets the location properly to the PSDrive.
                    }

                else
                {
                    throw "You are not currently connected to a CMSite Provider Please Connect and try again"
                }
            }
            write-Verbose "Succesfully validated connection to a CMProvider"
            return $true
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            write-error -Exception CMPatching -Message $errorMessage
            return $false
        }
}

function Test-Module
#Function that is designed to test a module if it is loaded or not. 
{
    [CMdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$ModuleName,
        [Parameter(Mandatory = $false)]
        [bool]$Remediate
    )
    If(Get-Module -Name $ModuleName)
    #Checks if the module is currently loaded and if it is then return true.
    {
        Write-Log -Message "The module was already loaded return TRUE"
        return $true
    }
    If((Get-Module -Name $ModuleName) -ne $true)
    #Checks if the module is NOT loaded and if it's not loaded then check to see if remediation is requested. 
    {
        Write-Log -Message "The Module was not already loaded evaluate if remediation flag was set"
        if($Remediate -eq $true)
        #If the remediation flag is selected then attempt to import the module. 
        {
            try 
            {
                    if($ModuleName -eq "ConfigurationManager")
                    #If the module requested is the Configuration Manager module use the below method to try to import the ConfigMGr Module.
                    {
                        Write-Verbose -Message "Non-Standard module requested run pre-written function"
                        Write-Log -LogLevel 2 -Message "Attempting to import a non standard module using the CM-Module function"
                        Get-CMModule
                        #Runs the command to get the COnfigMgr module if its needed. 
                        write-log -LogLevel 1 -Message "Succesfully imported the configuration manager module."
                        return $true
                    }
                    else
                    {
                    Write-Log -Message "Remediation flag WAS set now attempting to import module $ModuleName"
                    Import-Module -Name $ModuleName
                    #Import  the other module as needed - if they have no custom requirements.
                    Write-Log -Message "Succesfully improted the module $ModuleName"
                    Return $true
                    }
            }
            catch 
            {
                Write-Log -LogLevel 3 -Message "Failed to import the module $ModuleName"
                Set-Location $StartingLocation
                break
            }
        }
        else {
            #Else return the fact that it's not applicable and return false from the execution.
            {
                Return $false
            }
        }
    }
}

Function Start-Log
#Set global variable for the write-log function in this session or script.
{
	[CmdletBinding()]
    param (
	[string]$FilePath
 	)
    try
    	{
			#Confirm the provided destination for logging exists if it doesn't then create it.
			if (!(Test-Path $FilePath))
				{
	    			#Create the log file destination if it doesn't exist.
	    			New-Item $FilePath -Type File | Out-Null
				}
				## Set the global variable to be used as the FilePath for all subsequent Write-Log
				## calls in this session
				$global:ScriptLogFilePath = $FilePath
    	}
    catch
    {
		#In event of an error write an exception
        Write-Error $_.Exception.Message
    }
}

Function Write-Log
#Write the log file if the global variable is set
{
	param (
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [Parameter()]
    [ValidateSet(1, 2, 3)]
    [string]$LogLevel = 1
   )
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    #$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath
    if($writetoscreen -eq $true){
        switch ($LogLevel)
        {
            '1'{
                Write-Verbose $Message -ForegroundColor Gray
                }
            '2'{
                Write-Verbose $Message -ForegroundColor Yellow
                }
            '3'{
                Write-Verbose $Message -ForegroundColor Red
                }
            Default {}
        }
    }

    if($writetolistbox -eq $true){
        $result1.Items.Add("$Message")
    }
}
#endregion HelperFunctions
############################################

############################################
#Region CreateDeploymnets

#This region does all of the work for the script. Any changes tot eh script should be made in this section adn NOT to the above calculation
#and helper function regions. Use the below section for planning and calculating how to implement automated configmgr deployments in the future. 

$LogPath = "C:\scripts\logs\"
#Sets the log path for the logs to be stored in this can be changed as needed.
$LogFile = $LogPath + "Deployments.Log"
#This sets the name of the log file you can set it to whatever you would like it to be as long as it is set to .LOG
$StartingLocation = Get-Location
#This section retrieves the starting location of the script. This is then used to return to this location at the very end of the script. 
#This is becuase otherwise it would cause you to end up in the PR1: PSDrive. 
if(!(Test-Path $LogPath))
#Because of the current way the start/log function is written this next section bypasses the need to re-write that function. 
    {
        Write-Verbose "Creating Log file" -Verbose
        New-Item -ItemType Directory -Path $LogPath | Out-Null
        #This item creates the folder structure down to where the log files live. 
    }
Start-Log -FilePath $LogFile
#This starts the process that set up all of the logs for the future of the script. 
if($Pilot)
#If the PILOT switch is specified with the script this section of the code block is run. This is designed to allow all of the pilot 
#Deployments to be created. This allows all of the deployments to be created one day and then all of the other ADRS to run at another time. 
    {
        Write-Verbose -message "Starting Pilot Patching Calculations" -Verbose
        Write-Log -Message "Starting Pilot Patching Start Time Calculations" -loglevel 1
        $StartDate = Get-StartDate -PatchingOffset 2
        #This process sets the offset the above section should be set per organization and their organizations Pilot needs.
        #This particular offset of 2 - will cause the pilot to start on thursday for Desktops and servers. 
        Write-Verbose -Message "Starting setting deployment start time variables for workstations and servers"
        Write-Log -Message "Starting setting deployment start time variables for workstations and servers" -loglevel 1
        $WorkstationDeploymentStartTime = Get-Date -Date $StartDate -Hour 3 -Minute 00 -Second 00
        #Sets the start time for workstations in this case all workstation deployments start at 3 AM
        $ServerDeploymentstartTime = Get-Date -Date $StartDate -Hour 0 -Minute 00 -Second 00
        #Sets the start time for workstations in this case all Server deployments start at 12 AM
        Write-Verbose -Message "Now attempting to connect to configuration Manager" -Verbose
        Test-ConfigMgrAvailable -Remediate:$true -Verbose | Out-Null
        #Runs the test to make sure we are in the ConfigMgr drive or on a computer that can access the configMGr drive and cmdlets.
        $ServerCollections = Get-CMcollection -name "SUM - Server - Automatic - Pilot"
        $WorkstationCollections = Get-CMCollection -name "SUM - Workstations - Pilot"
        #This gets the collections that are needed to create the pilot deploymens for configmgr - You can change these as needed
        $CurrentServerMonthSUG = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Servers*")}
        #This does some math to find the software update group that should get deployed based on the most recently created SUG that matches the standard named ADRS for Servers.
        $CurrentWorkstationMonthSug = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Workstations*")}
        #This does some math to find the software update group that should get deployed based ont eh most recently created SUG that mathces the standard name for workstations
        $CurrentAncillaryMonthSug = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Ancillary*")}
        #This does some math to find the software update group that should get deployed based ont eh most recently created SUG that mathces the standard name for Ancillary products
        if(($CurrentWorkstationMonthSug.LocalizedDisplayName.count -gt 1 -or $CurrentWorkstationMonthSug.LocalizedDisplayName.count -eq 0) -or ($CurrentServerMonthSUG.LocalizedDisplayName.count -gt 1 -or $CurrentServerMonthSUG.LocalizedDisplayName.count -eq 0) -or ($CurrentAncillaryMonthSUG.LocalizedDisplayName.count -gt 1 -or $CurrentAncillaryMonthSUG.LocalizedDisplayName.count -eq 0))
        #Quick check to make sure that only 1 SUG has been selected for each of the ADRs if more than one have been selected something has gone wrong in the naming structure.
        {
            Write-Log -LogLevel 3 -message "You have accidentally caused multiple sugs to meet the criteria please examine the criteria"
            #Blows an error and then breaks the script.
            Write-Error "Please review the log file for more accurate reasons"
            Set-Location $StartingLocation
            break
        }
        try
        #This starts a try block to set up the deployments if it breaks then the try catch is triggered. 
        {
            Write-Verbose -Message "Now attempting to create the server deployment" -Verbose
            Write-Log -Message "Now attempting to create the server deployment"
            new-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentServerMonthSUG.LocalizedDisplayName -DeploymentName "ADR - Server - $((Get-Date).Year) $(get-date -uformat %B) - Pilot" -Description "ADR - Server - $((Get-Date).Year) $((Get-Date).Month) - Pilot" -AcceptEula -CollectionName $ServerCollections.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            #Creates the Deployment for the Server Pilot
            Write-Verbose -Message "Succesfully created the server deployment" -Verbose
            Write-Log -Message "Succesfully created the server deployment"
            Write-Verbose -Message "Now creating the workstation deployment" -Verbose
            Write-log -Message "Now creating the workstation deployment"
            new-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Pilot" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Pilot" -AcceptEula -CollectionName $WorkstationCollections.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $WorkstationDeploymentStartTime -DeadlineDateTime $WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            #Creates the Deployment for the workstations for Pilots
            Write-Verbose -Message "Succesfully created the workstation deployment" -Verbose
            Write-Log -Message "Succesfully created the workstation deployment"
            Write-Verbose -Message "Now creating the ancillary software deployment for Workstations" -Verbose
            Write-log -Message "Now creating the ancillary software deployment for Workstations" -Verbose
            new-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Pilot" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Pilot" -AcceptEula -CollectionName $WorkstationCollections.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $WorkstationDeploymentStartTime -DeadlineDateTime $WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            #Creates the deployment for the Ancillary products for pilots for Servers
            Write-Verbose -Message "Succesfully created  the ancillary software deployment for Workstations" -Verbose
            Write-log -Message "Succesfully created  the ancillary software deployment for Workstations" -Verbose
            Write-Verbose -Message "Now creating the ancillary software deployment for Servers" -Verbose
            Write-log -Message "Now creating the ancillary software deployment for Servers" -Verbose
            new-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Pilot" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Pilot" -AcceptEula -CollectionName $ServerCollections.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            #Creates the deployment for the Ancillary products for Pilots for Workstations
            Write-Verbose -Message "Succesfully created the ancillary software deployment for Servers" -Verbose
            Write-log -Message "Succesfully created the ancillary software deployment for Servers" -Verbose
        }
        catch
        {
            Write-Log -Message "$($_.Exception.Message)" -logLEvel 3
            Write-Error -Message $_.Exception.Message
            #If an error of any type occurs then end here. 
            Set-Location $StartingLocation
            break
        }
    }
if($Production)
#If the production flag is set then this section is triggered and creates the software deployment for production machines.
    {
        Write-Verbose -Message "Starting calculation for production patching schedule" 
        write-log -loglevel 1 -Message "Starting calculation for production patching schedule" 
        $Startdate = Get-StartDate -PatchingOffset 6
        #Creates the start date for patches change the number based on your environemnt or needs.
        Write-Verbose -Message "Starting setting deployment start time variables for workstations and servers for Production"
        Write-Log -Message "Starting setting deployment start time variables for workstations and servers for Production" -loglevel 1
        $WorkstationDeploymentStartTime = Get-Date -Date $StartDate -Hour 3 -Minute 00 -Second 00
        #Sets the workstation deployment start date.
        $ServerDeploymentstartTime = Get-Date -Date $StartDate -Hour 0 -Minute 00 -Second 00
        #Sets teh server deployment start date.
        Write-Verbose -Message "Deployment start time variables for workstations $($workstationDeploymentStartTime) and servers is $($ServerDeploymentStartTime)"
        Write-Log -Message "Deployment start time variables for workstations $($workstationDeploymentStartTime) and servers is $($ServerDeploymentStartTime)" -loglevel 1
        Write-Verbose -Message "Now attempting to connect to configuration Manager" -Verbose
        write-log -Message "Now attempting to connect to configuration Manager" -LogLevel 1
        Test-ConfigMgrAvailable -Remediate:$true -Verbose | Out-Null
        Write-Verbose -Message "Now retriveing production collections"
        $ServerAutomaticCollection = Get-CMcollection -name "SUM - Server - Automatic"
        $ServerManualCollection = Get-CMCollection -Name "SUM - SERVER - MANUAL"
        $ServerAvailableCollection = Get-CMCollection -Name "SUM - SERVER - Available"
        $WorkstationCollections = Get-CMCollection -name "SUM - Workstations - Stage*"
        #Retrieves all of the collections that will be used under the above naming standard.
        $CurrentServerMonthSUG = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Servers*")}
        $CurrentWorkstationMonthSug = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Workstations*")}
        $CurrentAncillaryMonthSug = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -gt ((Get-date).AddDays(-7))) -and ($_.LocalizedDisplayName -like "ADR - Ancillary*")}
        #Retreives all of the software update groups that will be used for deploying softwre. 
        if(($CurrentWorkstationMonthSug.LocalizedDisplayName.count -gt 1 -or $CurrentWorkstationMonthSug.LocalizedDisplayName.count -eq 0) -or ($CurrentServerMonthSUG.LocalizedDisplayName.count -gt 1 -or $CurrentServerMonthSUG.LocalizedDisplayName.count -eq 0) -or ($CurrentAncillaryMonthSUG.LocalizedDisplayName.count -gt 1 -or $CurrentAncillaryMonthSUG.LocalizedDisplayName.count -eq 0))
        #Quick check to make sure that only 1 SUG has been selected for each of the ADRs if more than one have been selected something has gone wrong in the naming structure.
        {
            Write-Log -LogLevel 3 -message "You have accidentally caused multiple sugs to meet the criteria please examine the criteria"
            #Blows an error and then breaks the script.
            Write-Error "Please review the log file for more accurate reasons"
            Set-Location $StartingLocation
            break
        }
        try
        {
            Write-Verbose -Message "Now attempting to create the Production Server Deployment for AUTOMATIC Patch and reboot" -Verbose
            Write-Log -Message "Now attempting to create the Production Server Deployment for AUTOMATIC Patch and reboot"
            #Creates the automatic deployment collection install
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentServerMonthSUG.LocalizedDisplayName -DeploymentName "ADR - Server - $((Get-Date).Year) $(get-date -uformat %B) - Production - Automatic" -Description "ADR - Server - $((Get-Date).Year) $((Get-Date).Month) - Production - Automatic" -AcceptEula -CollectionName $ServerAutomaticCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Automatic" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production - Automatic" -AcceptEula -CollectionName $ServerAutomaticCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            Write-Verbose -Message "Now attempting to create the Production Server Deployment for AUTOMATIC Patch and MANUAL reboot" -Verbose
            Write-Log -Message "Now attempting to create the Production Server Deployment for AUTOMATIC Patch and MANUAL reboot"
            #Creates the manual deployment that suppresses the reboot
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentServerMonthSUG.LocalizedDisplayName -DeploymentName "ADR - Server - $((Get-Date).Year) $(get-date -uformat %B) - Production - Manual" -Description "ADR - Server - $((Get-Date).Year) $((Get-Date).Month) - Production - Manual" -AcceptEula -CollectionName $ServerManualCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop -RestartServer:$true | Out-Null
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Manual" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production - Manual" -AcceptEula -CollectionName $ServerManualCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop -RestartServer:$true | Out-Null
            Write-Verbose -Message "Now attempting to create the Production Server Deployment for AVAILABLE Patch and MANUAL reboot" -Verbose
            Write-Log -Message "Now attempting to create the Production Server Deployment for AVAILABLE Patch and MANUAL reboot"
            #Creates the manual deployment that suppresses the reboot
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentServerMonthSUG.LocalizedDisplayName -DeploymentName "ADR - Server - $((Get-Date).Year) $(get-date -uformat %B) - Production - Available" -Description "ADR - Server - $((Get-Date).Year) $((Get-Date).Month) - Production - Available" -AcceptEula -CollectionName $ServerAvailableCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Available -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Available" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production - Available" -AcceptEula -CollectionName $ServerAvailableCollection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$false -AvailableDateTime $ServerDeploymentstartTime -DeadlineDateTime $ServerDeploymentstartTime -DeploymentType Available -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
            Write-Verbose -Message "Succesfully created the PRODUCTION server deployments" -Verbose
            Write-Log -Message "Succesfully created the PRODUCTION server deployments"
            Write-Verbose -Message "Now creating the workstation deployment" -Verbose
            Write-log -Message "Now creating the workstation deployments"
            foreach($Collection in $WorkstationCollections)
            #For each collection of the workstation collections (Stage 1 - Stage 5) will have the deployments get created. 
            {
                #The switches below are then selected for stages 1 - 5 for deploying the patches as needed for workstations and ancillary products.
                switch ($Collection.Name) {
                    "SUM - Workstations - Stage 1"
                    {
                        Write-Verbose -Message "Now creating Production Workstation Deployments for Phase 1 - Ancillary and OS start time is $($WorkstationDeploymentStartTime)" -Verbose
                        Write-Log -loglevel 1 -Message "Now creating Production Workstation Deployments for Phase 1 - Ancillary and OS start time is $($WorkstationDeploymentStartTime)"
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 1" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $WorkstationDeploymentStartTime -DeadlineDateTime $WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 1" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $WorkstationDeploymentStartTime -DeadlineDateTime $WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        #Creates the deployments for the Stage 1 Deployments for both the Ancilalry and the workstaiton collection
                    }
                    "SUM - Workstations - Stage 2"
                    { 
                        $Stage2WorkstationDeploymentStartTime = $WorkstationDeploymentStartTime.AddDays(1) 
                        Write-Verbose -Message "Now creating Production Workstation Deployments for Phase 2 - Ancillary and OS start time is $($Stage2WorkstationDeploymentStartTime)" -Verbose
                        Write-Log -loglevel 1 -Message "Now creating Production Workstation Deployments for Phase 2 - Ancillary and OS start time is $($Stage2WorkstationDeploymentStartTime)"
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 2" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage2WorkstationDeploymentStartTime -DeadlineDateTime $Stage2WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 2" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage2WorkstationDeploymentStartTime -DeadlineDateTime $Stage2WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        #Creates the deployments for the Stage 2 Deployments for both the Ancilalry and the workstaiton collection
                    }
                    "SUM - Workstations - Stage 3"
                    {
                        $Stage3WorkstationDeploymentStartTime = $WorkstationDeploymentStartTime.AddDays(2) 
                        Write-Verbose -Message "Now creating Production Workstation Deployments for Phase 3 - Ancillary and OS start time is $($Stage3WorkstationDeploymentStartTime)" -Verbose
                        Write-Log -loglevel 1 -Message "Now creating Production Workstation Deployments for Phase 3 - Ancillary and OS start time is $($Stage3WorkstationDeploymentStartTime)"
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 3" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage3WorkstationDeploymentStartTime -DeadlineDateTime $Stage3WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 3" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage3WorkstationDeploymentStartTime -DeadlineDateTime $Stage3WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        #Creates the deployments for the Stage 3 Deployments for both the Ancilalry and the workstaiton collection
                    }
                    "SUM - Workstations - Stage 4"
                    {
                        $Stage4WorkstationDeploymentStartTime = $WorkstationDeploymentStartTime.AddDays(3)
                        Write-Verbose -Message "Now creating Production Workstation Deployments for Phase 4 - Ancillary and OS start time is $($Stage4WorkstationDeploymentStartTime)" -Verbose
                        Write-Log -loglevel 1 -Message "Now creating Production Workstation Deployments for Phase 4 - Ancillary and OS start time is $($Stage4WorkstationDeploymentStartTime)"
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 4" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage4WorkstationDeploymentStartTime -DeadlineDateTime $Stage4WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 4" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage4WorkstationDeploymentStartTime -DeadlineDateTime $Stage4WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        #Creates the deployments for the Stage 4 Deployments for both the Ancilalry and the workstaiton collection
                    }
                    "SUM - Workstations - Stage 5"
                    {
                        $Stage5WorkstationDeploymentStartTime = $WorkstationDeploymentStartTime.AddDays(4)
                        Write-Verbose -Message "Now creating Production Workstation Deployments for Phase 5 - Ancillary and OS start time is $($Stage5WorkstationDeploymentStartTime)" -Verbose
                        Write-Log -loglevel 1 -Message "Now creating Production Workstation Deployments for Phase 5 - Ancillary and OS start time is $($Stage5WorkstationDeploymentStartTime)"
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentWorkstationMonthSug.LocalizedDisplayName -DeploymentName "ADR - Workstation - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 5" -Description "ADR - Workstation - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage5WorkstationDeploymentStartTime -DeadlineDateTime $Stage5WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $CurrentAncillaryMonthSug.LocalizedDisplayName -DeploymentName "ADR - Ancillary - $((Get-Date).Year) $(get-date -uformat %B) - Production - Stage 5" -Description "ADR - Ancillary - $((Get-Date).Year) $((Get-Date).Month) - Production" -AcceptEula -CollectionName $Collection.Name -RequirePostRebootFullScan:$true -DownloadFromMicrosoftUpdate:$true -AvailableDateTime $Stage5WorkstationDeploymentStartTime -DeadlineDateTime $Stage5WorkstationDeploymentStartTime -DeploymentType Required -UserNotification DisplaySoftwareCenterOnly -ProtectedType RemoteDistributionPoint -ErrorAction Stop | Out-Null
                        #Creates the deployments for the Stage 5 Deployments for both the Ancilalry and the workstaiton collection
                    }
                }
                Write-Verbose -Message "The deployments for $($Collection.Name) has been succesfully created" -Verbose
                Write-Log -LogLevel 1 "The deployments for $($Collection.Name) has been succesfully created"
            }
            Write-Verbose -Message "Completed all production deployments now triggering cleanup of deployments older than 30 days created using the ADRS"
            Write-Log -Message "Completed all production deployments now triggering cleanup of deployments older than 30 days created using the ADRS" -LogLevel 1
            $OLDDEPLOYMENTS = Get-CMsoftwareUpdateDeployment | Where-Object{($_.CreationTime -lt ((Get-date).AddDays(-20))) -and ($_.AssignmentName -Match "ADR - Server|ADR - Workstation|ADR - Ancillary")} 
            #This gets all of the old deployments for SUGS that are based on ADDR's once they are retrieved -> and removes all of the old ones
            $OLDSUGS = Get-CMsoftwareUpdateGroup | Where-Object{($_.DateCreated -lt ((Get-date).AddDays(-60))) -and ($_.LocalizedDisplayName -Match "ADR - Server|ADR - Workstation|ADR - Ancillary")} 
            #Gathers all of the old software update groups that are older than three months (To allow a brief historic time to use the group)
            if($OLDDEPLOYMENTS.count -gt 0)
            {
                foreach($Deployment in $OLDDEPLOYMENTS)
                {
                    try
                    {
                        Write-Log -Message "Now removing the old depoyment $($Deployment.AssignmentName) created on $($Deployment.CreationTime)"
                        Write-Verbose "Now removing the old depoyment $($Deployment.AssignmentName) created on $($Deployment.CreationTime)" -Verbose
                        Remove-CMSoftwareUpdateDeployment -AssignmentUniqueID $Deployment.AssignmentUniqueID -Force -ErrorAction Stop
                        #Removes all of the old deployments.
                    }
                    Catch
                    {
                        Write-Log -LogLevel 3 -Message "Something went wrong when trying to remove the old software deployments please investigate the old deployments"
                        #writes a log about the error occuring
                        Write-Log -LogLevel 3 -Message "$($_.Exception.Message)"
                        #Writes the details of the error to the log
                        Write-Error -Exception $_.Exception.Message
                        #writes the error to to the exception stream
                    }
                }
            }
            else 
            {
                Write-Log -LogLevel 1 -Message "We found no old software update deployments to remove the script has been run multiple times OR the deployments were manualy removed"   
                Write-Verbose -Message "We found no old software update deployments to remove the script has been run multiple times OR the deployments were manualy removed"
            }
            if($OLDSUGS.count -gt 0)
            {
                foreach($SoftwareUpdateGroup in $OLDSUGS)
                {
                    try
                    {
                        Write-Log -Message "Now removing the old Software Updat Group $($SoftwareUpdateGroup.LocalizedDisplayName) created on $($SoftwareUpdateGroup.DateCreated)"
                        Write-Verbose -Message "Now removing the old Software Updat Group $($SoftwareUpdateGroup.LocalizedDisplayName) created on $($SoftwareUpdateGroup.DateCreated)"
                        Remove-CMSoftareUpdateGroup -Name $SoftwareUpdateGroup.LocalizedDisplayName -Force -ErrorAction Stop
                        #Removes all of the old Software Update groups.
                    }
                    Catch
                    {
                        Write-Log -LogLevel 3 -Message "Something went wrong when trying to remove the old software update group please investigate the old groups"
                        #Writes an error removing the software update group
                        Write-Log -LogLevel 3 -Message "$($_.Exception.Message)"
                        #writes an error removing the software update group and the details from the error
                        Write-Error -Exception $_.Exception.Message
                        #writes an error to the error stream
                    }
                }
            }
            else
            {
                Write-Log -LogLevel 1 -Message "We found no old software update groups to remove the script has been run multiple times OR the groups were manualy removed"   
                Write-Verbose -Message "We found no old software update groups to remove the script has been run multiple times OR the groups were manualy removed" 
            }
            Write-Verbose -Message "The script has completed for additional details you can review the log file stored in C:\Scripts\Logs\Deployments.Log" -Verbose
            Write-Log -Message "The script has completed for additional details you can review the log file stored in C:\Scripts\Logs\Deployments.Log"
        }
        catch
        {
            Write-Log -Message "$($_.Exception.Message)" -logLEvel 3
            Write-Error -Message $_.Exception.Message
        }
    }

Set-Location $StartingLocation
#endregion CreateDeploymnets
############################################