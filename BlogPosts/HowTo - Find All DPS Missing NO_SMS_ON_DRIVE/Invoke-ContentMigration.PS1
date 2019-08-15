<#
.SYNOPSIS
    This script is used to gather information about distribution points and if the C:\ drive has the NO_SMS_ON_DRIVE.SMS file present. 
    For Servers that do NOT have the file present there is an option to copy the server tools and migrate the content library

.DESCRIPTION
    This script is desinged if you are an organization with a large number of Distribution Points and find that those distribution points were 
    originally not properly configured. One of the key lacks of configuration is that the NO_SMS_ON_DRIVE.SMS file was missing from the C:\ drive.
    The script also has a parameter that if engaged will allow the the content library transfer tool to migrate the content away from the offending drive
    that is missing the blocker file to the drive of your choosing.

.LINK
    
.NOTES
          FileName: Invoke-ContentMigration.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-08-15
          Modified: 2019-08-15

          Version - 0.0.1 - (2019-08-15)

          Shortcut for the Default Server Tools Path $(split-path(Split-Path(split-path $env:SMS_ADMIN_UI_PATH)))\tools\ServerTools
\\PROBRESCM01\C$\Prgram

.EXAMPLE

#>

[cmdletbinding(DefaultParameterSetName="None")]
param(
    [Parameter(HelpMessage = "Enter your Site Code",Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(HelpMessage = "Enter your Server Name",Mandatory=$true)]
    [string]$ConfigMgrServer,
    [Parameter(HelpMessage = "Path to the Server Tools folder if not specified we assume it's in the default location",ParameterSetName = "MigrationRequired",Mandatory=$true)]
    [string]$ServerToolsPath,
    [Parameter(HelpMessage = "Source drive that should be used to check for NOSMS on Drive.",Mandatory=$true)]
    [string]$SourceDrive = "C",
    [Parameter(HelpMessage ="Destination Drive - DO NOT include a COLON",ParameterSetName = "MigrationRequired",Mandatory=$true )]
    [string]$DestinationDrive,
    [Parameter(HelpMessage ="Switch that is used to migrate the content if desired",ParameterSetName = "MigrationRequired",Mandatory=$true )]
    [switch]$MigrateContent
)
begin{
    if($ServerToolsPath -and !(Test-Path -Path $ServerToolsPath)){
        Write-Error -Message "We couldn't find the Server tools path that was provided. Exiting..."
        break
    }
    if(!(Test-NetConnection -ComputerName $ConfigMgrServer -Port 445)){
        Write-Error -Message "Cannot connect on the SMB port 445 for WMI accesss and remote PS" -ErrorAction Stop
        break
    }
}

process{
    $DPList = Get-WmiObject -ComputerName $ConfigMgrServer -Namespace root\sms\site_$SiteCode -Query "select distinct ServerName from sms_distributionpointInfo"
    $Status = New-Object System.Collections.ArrayList
    ForEach($DP in $DPList){
    $Result = Test-Path -Path "filesystem::\\$($DP.ServerName)\$($SourceDrive)$\NO_SMS_ON_DRIVE.SMS"
    if($Result -eq $false){
        $DriveAvailable = Test-Path -Path "filesystem::\\$($DP.ServerName)\$($SourceDrive)"
        if($DriveAvailable -eq $false){
            $Result = "NO SUCH DESTINATION"
        }
    }
    Write-Verbose -Message "The Server $($DP.ServerName) returned $($Result) for having the NO_SMS_ON_DRIVE.SMS" -Verbose
    $hash = [ordered]@{
            SERVERNAME = $DP.ServerName
            RESULT = $Result
    }
    $CurrentObject = New-Object -TypeName PSObject -Property $hash
    $Status.Add($CurrentObject) | Out-Null
    }
    $Status
    if($MigrateContent){
        $Status | Where-Object {$_.Result -eq $false} | ForEach-Object {if(!(test-path -path "filesystem::\\$($_.ServerName)\$($SourceDrive)$\ServerTools")){Copy-item -Container $SerVerToolsPath -Recurse -Destination "filesystem::\\$($_.ServerName)\$($SourceDrive)$\"}}
        #NOTE YOU MUST SET THE DRIVE LETTER YOU WANT TO MOVE THE CONTENT TO DOWN HERE
        $Status | Where-Object {$_.Result -eq $false} | ForEach-Object {Invoke-Command -ComputerName $ConfigMgrServer -ScriptBlock {C:\ServerTools\contentlibrarytransfer.exe -SourceDrive $using:SourceDrive -TargetDrive $using:DestinationDrive} -AsJob}
        Do{
            $JobStates = $Status | Where-Object {$_.Result -eq $false} | ForEach-Object {Get-Job | Where-Object {$_.Location -match $_.ServerName}}
            Write-Progress -Activity "Content Migration" -CurrentOperation "$(($JobStates.State | Where-Object {$_ -eq "Completed"}).Count) / $(($JobStates.State).Count) jobs have completed"   -PercentComplete $($(($JobStates.State).Count)/(($JobStates.State | Where-Object {$_ -eq "Completed"}).Count + 1) * 100)
            Start-Sleep -Seconds 60
        } 
        Until(($JobStates.State | Where-Object {$_ -ne "Completed"}).Count -eq 0)
        Write-Verbose -Message "Content migration has finished now returning the results from each job. The result SHOULD be 'Content Library Transfer is now complete' if NOT please review the log generated for that servers session" -Verbose
        ForEach($Job in $JobStates){
            $Content = Receive-Job -id $Job.Id
            if($Content[$($Content.Length - 3)] -match "Content Library Transfer is now complete !!" ){
                Write-Verbose -Message "$($Job.Location) returned a positive result" -Verbose
            }
            else{
                Write-Warning -Message "$($Job.Location) returned a NEGATIVE result inspect this job" -WarningAction Continue
            }
            Out-File -FilePath $PSScriptRoot\$($Job.Location).LOG -InputObject $Content
            Remove-Job -Id $Job.Id
        }
    }
}