<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Untitled-1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-10-10
          Modified: 2019-10-10

          Version - 0.0.0 - (2019-10-10)


          TODO:
               [ ] Script Main Goal
               [ ] Script Secondary Goal

.EXAMPLE

#>

[cmdletbinding()]
param()
begin{

#region helperfunctions
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
            if((Get-location -Verbose:$false).Path -ne (Get-location -PSProvider 'CmSite' -Verbose:$false).Path)
            #Checks if the current location is the - PS provider for the CMSite server. 
            {
                Write-Verbose -Message "The location is NOT currently the CMDrive"
                if($Remediate)
                #If the remediation field is set then it attempts to set the current location of the path to the CMSite server path. 
                    {
                        Write-Verbose -Message "Remediation was requested now attempting to set location to the the CM PSDrive"
                        Set-Location -Path (((Get-PSDrive -PSProvider CMSite -Verbose:$false).Name) + ":") -Verbose:$false
                        Write-Verbose -Message "Succesfully connected to the CMDrive"
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
        Write-Verbose -Message "The module was already loaded return TRUE"
        return $true
    }
    If((Get-Module -Name $ModuleName) -ne $true)
    #Checks if the module is NOT loaded and if it's not loaded then check to see if remediation is requested. 
    {
        Write-Verbose -Message "The Module was not already loaded evaluate if remediation flag was set"
        if($Remediate -eq $true)
        #If the remediation flag is selected then attempt to import the module. 
        {
            try 
            {
                    if($ModuleName -eq "ConfigurationManager")
                    #If the module requested is the Configuration Manager module use the below method to try to import the ConfigMGr Module.
                    {
                        Write-Verbose -Message "Non-Standard module requested run pre-written function"
                        Get-CMModule
                        #Runs the command to get the COnfigMgr module if its needed. 
                        Write-Verbose -Message "Succesfully loaded the module"
                        return $true
                    }
                    else
                    {
                    Write-Verbose -Message "Remediation flag WAS set now attempting to import module $($ModuleName)"
                    Import-Module -Name $ModuleName
                    #Import  the other module as needed - if they have no custom requirements.
                    Write-Verbose -Message "Succesfully improted the module $ModuleName"
                    Return $true
                    }
            }
            catch 
            {
                Write-Error -Message "Failed to import the module $($ModuleName)"
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
#endregion helperfunctions

function Get-Information{
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "This parameter specifies the AD Group name to use")]
        [string]$GroupName,
        [Parameter(HelpMessage = "This parameter specifies the collectionID to add the group to")]
        [string]$CollectionID
    )
    begin{
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
    }
    process{
            $objForm = New-Object System.Windows.Forms.Form 
            $objForm.Text = "SCConfigMgr - Add AD Group To Collection"
            $objForm.Icon = "$(split-path $script:MyInvocation.MyCommand.Path)\SCConfigMgrLogo-Square.ico"
            $objForm.BackColor = [System.Drawing.Color]::LightGray
            $objForm.Size = New-Object System.Drawing.Size(480,300) 
            $objForm.StartPosition = "CenterScreen"
        
            $objForm.KeyPreview = $True
            $objForm.Add_KeyDown({
                if ($_.KeyCode -eq "Enter" -or $_.KeyCode -eq "Escape"){
                    $objForm.Close()
                }
            })
        
            #OK Button
            $OKButton = New-Object System.Windows.Forms.Button
            $OKButton.Location = New-Object System.Drawing.Size(10,225)
            $OKButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $OKButton.Size = New-Object System.Drawing.Size(75,23)
            $OKButton.Text = "OK"
            $OKButton.Add_Click({$objForm.Close()})
            $objForm.Controls.Add($OKButton)
            
            #Cancel Button
            $CancelButton = New-Object System.Windows.Forms.Button
            $CancelButton.Location = New-Object System.Drawing.Size(375,225)
            $CancelButton.Size = New-Object System.Drawing.Size(75,23)
            $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $CancelButton.Text = "Cancel"
            $CancelButton.Add_Click({
                 $objForm.Close()
             })
            $objForm.Controls.Add($CancelButton)
                  
            ###ADGroup Information###
            $GroupLabel = New-Object System.Windows.Forms.Label
            $GroupLabel.Location = New-Object System.Drawing.Size(10,20) 
            $GroupLabel.Size = New-Object System.Drawing.Size(315,20) 
            $GroupLabel.Text = "Enter The Group Name"
            $GroupLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $objForm.Controls.Add($GroupLabel) 
        
            $GroupTextBox= New-Object System.Windows.Forms.TextBox 
            $GroupTextBox.Location = New-Object System.Drawing.Size(10,40) 
            $GroupTextBox.Size = New-Object System.Drawing.Size(315,20)
            $GroupTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $GroupTextBox.Text = "GROUP-NAME-O1"
            $objForm.Controls.Add($GroupTextBox) 
        
            ###Collection ID Information###
            $CollectionLabel = New-Object System.Windows.Forms.Label
            $CollectionLabel.Location = New-Object System.Drawing.Size(10,70) 
            $CollectionLabel.Size = New-Object System.Drawing.Size(315,20) 
            $CollectionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionLabel.Text = "Specify the Collection ID"
            $objForm.Controls.Add($CollectionLabel)
        
             
            $CollectionTextBox = New-Object System.Windows.Forms.TextBox 
            $CollectionTextBox.Location = New-Object System.Drawing.Size(10,90) 
            $CollectionTextBox.Size = New-Object System.Drawing.Size(315,20) 
            $CollectionTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionTextBox.AutoSize = $True
            $CollectionTextBox.Text = "PR100023"
            $objForm.Controls.Add($CollectionTextBox)
        
            ###Site Server ID ###
            $SiteCodeLabel = New-Object System.Windows.Forms.Label
            $SiteCodeLabel.Location = New-Object System.Drawing.Size(10,120) 
            $SiteCodeLabel.Size = New-Object System.Drawing.Size(315,20) 
            $SiteCodeLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $SiteCodeLabel.Text = "Specify the Collection ID"
            $objForm.Controls.Add($SiteCodeLabel)
        
             
           $SiteCodeTextBox = New-Object System.Windows.Forms.TextBox 
           $SiteCodeTextBox.Location = New-Object System.Drawing.Size(10,140) 
           $SiteCodeTextBox.Size = New-Object System.Drawing.Size(315,20) 
           $SiteCodeTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
           $SiteCodeTextBox.AutoSize = $True
           $SiteCodeTextBox.Text = "PR1"
           $objForm.Controls.Add($SiteCodeTextBox)
        

            $objForm.Topmost = $True
            $objForm.Add_Shown({$objForm.Activate()})
            [void]$objForm.ShowDialog()
        
            $Hash = @{
                 GroupName = $GroupTextBox.Text
                 collectionID = $CollectionTextBox.Text
                 SiteCodeID = $SiteCodeTextBox.Text
            }
            $Object = New-Object -TypeName psobject -Property $Hash
            return $Object
        }
}

function New-ADGroupQuery{
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$GroupName,
        [parameter(Mandatory = $true)]
        [string]$CollectionID
        )
$GroupName = "$((Get-ADForest).Name)\\$GroupName"
$Query = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "$groupName"
"@
        Add-CMDeviceCollectionQueryMembershiprule -CollectionID $CollectionID -RuleName "All devices that are a member of AD Group $($GroupName)" -QueryExpression $Query
}
}
process{
    $StartingLocation = $(Get-Location).Path
    if(Test-ConfigMgrAvailable -Remediate:$true){
    $Information = Get-Information
    New-ADGroupQuery -GroupName $Information.GroupName -CollectionID $Information.collectionID
    }
}