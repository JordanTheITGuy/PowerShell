<# 
.SYNOPSIS 
    Simple full backup Script for WSUS database .DESCRIPTION $ServerName Chose the Server Name that hosts the SQL instance $BackupDirectory
    Choose the path to the location to backup the SQL database [int32]$BackupRetentiondays Specifiy the number of days you would like 
    to retain the database for $DatabaseName Specifify the database you would like to perform a full backup for.
    $LogDirectory Specifiy the directory you would like to send basic logging to $LogName Partially name the daily log file. 
 .EXAMPLE 
 .NOTES 
    FileName: SQL-BackupScript.ps1 
    Author: Jordan Benzing Contact: 
    @JordanTheItGuy 
    Created: 2018-09-06 
    Updated: 2018-09-06 
    Version history: 1.0.0 - (2018-09-06) Script created 
 #> 
 <# This can be used to enable support for parameterization with the script instead of using stored variables for a Scheduled task.

[CmdletBinding(SupportsShouldProcess=$true)] param([parameter(Mandatory = $true)] 
[string]$ServerName,
[parameter(Mandatory = $true)]
[string]$BackupDirectory,
[parameter(Mandatory = $true)]
[int32]$BackupRetentiondays,
[parameter(Mandatory = $true)]
[string]$DatabaseName, 
[Parameter(Mandatory = $True)] 
[string]$LogDirectory,
 [Parameter(Mandatory = $True)] 
 [string]$LogName )
  #> 
#See Description for explanation of the Below variables 
$ServerName = ""
$BackupDirectory = ""
[int32]$BackupRetentiondays = 3
$DatabaseName = ""
$LogDirectory = ""
$LogName = ""
function Write-Log {
    [CmdletBinding()] param( [Parameter(Mandatory = $False)] [string]$LogDirectory, [Parameter(Mandatory = $False)] [string]$LogName, [Parameter(Mandatory = $False)] [string]$Message, [Parameter(Mandatory = $false)] [switch]$LogCleanup ) try {
        if (Test-Path $LogDirectory) {
            #Validates the log direcory exists 
            if (($LogDirectory.Substring($LogDirectory.Length – 1)) -eq ‘\’) 
            #Checks the backslash is present at the end of the string if not then jumps to second loop and adds it back. 
            { 
                $LogFile = $LogDirectory + $LogName + "-" + (Get-Date -UFormat %m_%d_%y ).ToString() + ".TXT" 
                ((Get-Date).ToString() + " – " + $Message) >> $LogFile; 
            } 
            else { 
                $LogFile = $LogDirectory + $LogName + "-" + (Get-Date -UFormat %m_%d_%y ).ToString() + ".TXT" 
                ((Get-Date).ToString() + " – " + $Message) >> $LogFile; 
            } 
        } if ($LogCleanup) { Get-ChildItem -Path $LogDirectory -Filter $LogName* | Where-Object { $_.LastWriteTime -lt ((Get-Date).AddDays(-3)) } | Remove-Item } 
    }
    catch { 
        $ErrorMessage = $_.Exception.Message 
        Write-Error -Exception LoggingError -Message $ErrorMessage 
    } 
} 
function Start-backup {
    [CmdletBinding(SupportsShouldProcess = $true)] param(
        [parameter(Mandatory = $true)]
        [string]$ServerName,
        [parameter(Mandatory = $true)]
        [string]$BackupDirectory,
        [parameter(Mandatory = $true)]
        [int32]$BackupRetentiondays,
        [parameter(Mandatory = $true)]
        [string]$DatabaseName ) Begin {
        if ((Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "SQLPS" })) 
        #Checks to see if the SQL Module is available if the module is not available it cannot execute backups. 
        { $VerboseMessage = "The minimum required SQL Module is present you may continue" 
        Write-Verbose -Message "The minimum required SQL Module is present you may continue" 
        Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage } 
    } Process {
        try {
            #Import the SQLPS Module 
            Import-Module SQLPS -Verbose:$false $VerboseMessage = "Imported the Management Pack" 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
            Write-Verbose -Message $VerboseMessage $CurrentDate = Get-Date -UFormat %m_%d_%y $VerboseMessage = "Got the current date to use as the BAKName" 
            Write-Verbose -Message $VerboseMessage 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage $VerboseMessage = "Validating the retention days is negative if greater than 0 if not then making it negative" 
            Write-Verbose -Message $VerboseMessage 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
            #Above block completes initial variable setting and information gathering before attemping to do anything. i
            f($BackupRetentiondays -gt 0) 
            #Validates that backup retention days is not a positive number if it is makes it negative to only remove OLD backup files. 
            { $VerboseMessage = "Backup date is positive making it negative" 
            Write-Verbose -Message $VerboseMessage 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage $BackupRetentiondays = $BackupRetentiondays * -1 
                #Validaes and logs that the date was properly set to a negative value. 
            } 
            if (Test-Path -Path $BackupDirectory) {
                #Validates that the BackupDirectory Path is reachable and if it is reachable then continues on. 
                $VerboseMessage = "Managed to test the location the backups should be stored" 
                Write-Verbose -Message $VerboseMessage Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
                if (($BackupDirectory.Substring($BackupDirectory.Length – 1)) -eq ‘\’) {
                    #Validates the path ends with a \ in the prompt. Due to past experience with strings that don’t end in \ from a user stared doing this check 
                    $VerboseMessage = "Validated that the last character in the string is a \" 
                    Write-Verbose -Message $VerboseMessage 
                    Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage $BackupFileName = $DatabaseName + "-" + $CurrentDate + ".bak" $BackupFile = $BackupDirectory + $BackupFileName $VerboseMessage = "Created the Backup location string" 
                    Write-Verbose -Message $VerboseMessage 
                    Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
                    #Concatonate and builds the backup file location string. 
                } 
            }
            else {
                if (Test-Path -Path $BackupDirectory) 
                { #Validates that the path is reachable and continues on 
                    ##DEVNOTE## – This can be moved to top level and validated at start of run time to avoid multiple validation steps 
                    $BackupFileName = $DatabaseName + "-" + $CurrentDate + ".bak" 
                    $BackupFile = $BackupDirectory + $BackupFileName 
                    #Sets the backup fiel strings that will be used. 
                } 
            } $VerboseMessage = "Starting backup process" 
            Write-Verbose -Message $VerboseMessage 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            #Next line exeuctes the SQL Backup Statement from PowerShell 
            Backup-SqlDatabase -ServerInstance $ServerName -Database $DatabaseName -BackupFile $BackupFile 
            #Upon Completion Continues on 
            $VerboseMessage = "Completed the backup process – Now Calculating all files that can be removed" 
            Write-Verbose -Message $VerboseMessage 
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
            $AllBAK = Get-ChildItem -Path $BackupDirectory -Filter *.BAK | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays($BackupRetentiondays) -and $_.Name -eq $BackupFileName } 
            #Gatehrs list of files that meet the criteria for removal (Old backup clean up) 
            if ($AllBAK) {
                $VerboseMessage = "There are BAK files to be removed" 
                Write-Verbose -Message $VerboseMessage Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
                ForEach ($BAKFile in $AllBAK) {
                    #For each file that is in the list do the folowing  if($BAKFile.LastWriteTime -lt (Get-Date).AddDays($BackupRetentiondays)) 
                    { #Re-confirm that nothing slipped through initial filter and if it is really this old then remove #DEVNOTE#- This is not needed opimization can be removed since this age criteria was moved above to the filter. 
                        Remove-Item -Path $BAKFile.FullName -Force 
                        #Forces the removal of the Backup Files using the full name to ensure its the pathed to item. 
                        $Name = $BAKFile.Name 
                        $VerboseMessage = "Removed $Name" 
                        Write-Verbose -Message $VerboseMessage 
                        Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
                    } 
                } 
            } 
            else { 
                #If nothing met the backup purge criteria exits to here and continues on. 
                $VerboseMessage = "No backup files need to be removed" 
                Write-Verbose -Message "No backup files need to be removed" 
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
            } 
            #Logs completion of the process 
            $VerboseMessage = "Backup Process has been completed" 
            Write-Verbose -Message $VerboseMessage Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage 
        } 
        catch { Write-Error -Message "Something went wrong run the script manually with Verbose specified to validate" } 
    } 
} 
#Call functions using specified variables at script top to execute. 
Start-backup -ServerName $ServerName -BackupDirectory $BackupDirectory -BackupRetentiondays $BackupRetentiondays -DatabaseName $DatabaseName 
#Clean up log files older than 3 days this is hard coded
#DEVNOTE# – Circle back and make this optional to the end user 
Write-Log -LogDirectory $LogDirectory -logName $LogName -LogCleanup -Message "Cleaning up Old Log Files Older than 3 days."
Write-Log -LogDirectory $LogDirectory -logName $LogName -Message "Script Completed"