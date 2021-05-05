<#
.SYNOPSIS
    Peforms a simple full backup of a database with logging.

.DESCRIPTION
    Can be used for backing up SQL Server or WID databases.
.EXAMPLE
    SQL-BackupScript.ps1 -InstanceName '\\.\pipe\MICROSOFT##WID\tsql\query' -DatabaseName SUSDB -BackupDirectory X:\Backups -BackupRetentionDays 100
.NOTES
    FileName: SQL-BackupScript.ps1
    Author: Jordan Benzing
    Contact: @JordanTheItGuy
    Modified By: Thomas Garrity
    Created: 2018-09-06 
    Updated: 2021-05-05
    Version history: 2.0.0
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string]$InstanceName,

    [Parameter(Mandatory)]
    [string]$DatabaseName,

    [Parameter(Mandatory)]
    [string]$BackupDirectory,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$BackupRetentionDays = 30,

    [string]$LogDirectory = $BackupDirectory + '\Logs',

    [string]$LogName = $DatabaseName + '_BackupLog'
)

function Write-Log {
    [CmdletBinding()]
    param(
        [string]$LogDirectory,

        [string]$LogName,

        [string]$Message,

        [switch]$LogCleanup
    )
    try {
        if ((Test-Path -Path $LogDirectory) -eq $true) {
            if ($LogDirectory -like '*\') {
                $LogFilePath = $LogDirectory
            }
            else {
                $LogFilePath = $LogDirectory + '\'
            }
            $LogFile = $LogFilePath + $LogName + '-' + (Get-Date -UFormat %m_%d_%y) + '.TXT'
            ((Get-Date).ToString() + ' – ' + $Message) | Out-File -FilePath $LogFile -Append
        }
        else{
            New-Item -ItemType Directory -Path $FullReportDirPath -Force
        }

        if ($LogCleanup -eq $true) {
            Get-ChildItem -Path $LogDirectory -Filter $LogName* |
            Where-Object -FilterScript { $_.LastWriteTime -lt ((Get-Date).AddDays(-30)) } | Remove-Item
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error -Exception LoggingError -Message $ErrorMessage
    }
}

function Start-SQLBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$InstanceName,
        
        [parameter(Mandatory = $true)]
        [string]$BackupDirectory,
        
        [parameter(Mandatory = $true)]
        [int]$BackupRetentionDays,
        
        [parameter(Mandatory = $true)]
        [string]$DatabaseName
    )
    
    Begin {
        $Modules = Get-Module -ListAvailable
        $Module1 = 'SqlServer'
        $Module2 = 'SQLPS'

        if ($Modules.Name -contains $Module1){
            Import-Module -Name $Module1
            
            $VerboseMessage = "Imported the $Module1 module."
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            Write-Verbose -Message $VerboseMessage
        }
        elseif ($Modules.Name -contains $Module2){
            Import-Module -Name $Module2
            
            $VerboseMessage = "Imported the $Module2 module."
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            Write-Verbose -Message $VerboseMessage
        }
        else{
            $VerboseMessage = 'A required SQL Module was not found on the system.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            #Add code to exit the script
        }
    }

    Process {
        try {
            $CurrentDate = Get-Date -UFormat %m_%d_%y
            
            $VerboseMessage = 'Got the current date to use as the BAKName.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            
            $VerboseMessage = 'Backup date is positive. Making it negative.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage

            $BackupRetentionDays = $BackupRetentionDays * -1
            
            if ((Test-Path -Path $BackupDirectory) -eq $true) {
                $VerboseMessage = 'Managed to test the location the backups should be stored.'
                Write-Verbose -Message $VerboseMessage
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
                
                if ($BackupDirectory -like '*\') {
                    $BackupDirectoryPath = $BackupDirectory
                }
                else {
                    $BackupDirectoryPath = $BackupDirectory + '\'
                }

                $VerboseMessage = 'Validated that the last character in the string is a \.'
                Write-Verbose -Message $VerboseMessage
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
                    
                $BackupFileName = $DatabaseName + '-' + $CurrentDate + '.bak'
                    
                $BackupFile = $BackupDirectoryPath + $BackupFileName
                    
                $VerboseMessage = 'Created the backup location string.'
                Write-Verbose -Message $VerboseMessage
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            }

            $VerboseMessage = 'Starting backup process.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage

            Backup-SqlDatabase -ServerInstance $InstanceName -Database $DatabaseName -BackupFile $BackupFile

            $VerboseMessage = 'Completed the backup process. Now calculating all files that can be removed.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            
            $AllBAK = Get-ChildItem -Path $BackupDirectory -Filter *.BAK | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays($BackupRetentionDays) -and $_.Name -eq $BackupFileName }
            if ($AllBAK) {
                $VerboseMessage = 'There are BAK files to be removed.'
                Write-Verbose -Message $VerboseMessage
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            }
            else {
                $VerboseMessage = 'No backup files need to be removed.'
                Write-Verbose -Message $VerboseMessage
                Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
            }

            $VerboseMessage = 'Backup process has completed.'
            Write-Verbose -Message $VerboseMessage
            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $VerboseMessage
        }
        catch {
            #Write-Error -Message 'Something went wrong. Run the script manually with Verbose specified to validate.'
            throw
            $ErrorMessage = $Error[0].Exception
            Write-Error -Message $ErrorMessage

            <#
            $ErrorMessage = $_.Exception.Message
            Write-Error -Exception LoggingError -Message $ErrorMessage
            #>

            Write-Log -LogDirectory $LogDirectory -LogName $LogName -Message $ErrorMessage
        }
    }
}

Start-SQLBackup -InstanceName $InstanceName -DatabaseName $DatabaseName -BackupDirectory $BackupDirectory -BackupRetentionDays $BackupRetentionDays
Write-Log -LogDirectory $LogDirectory -logName $LogName -LogCleanup -Message 'Cleaning up log files older than 3 days.'
Write-Log -LogDirectory $LogDirectory -logName $LogName -Message 'Script completed.'
