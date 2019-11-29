# NOTE: Don't add any code before "using namespace System.Management.Automation"

#Requires -Version 5.0
#This next line loads the SMA - to make it pretty the easy way.
using namespace System.Management.Automation

$SiteServer = "SiteServer"
$SiteCode = "SiteCode"


Function Write-InformationColored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]$MessageData,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        [Switch]$NoNewline
    )

    $msg = [HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    Write-Information $msg
}

$DPS = Get-CimInstance -ComputerName $SiteServer -Namespace "root\sms\site_$($SiteCode)" -query "SELECT * FROM SMS_SystemResourceList WHERE RoleName='SMS Distribution Point'" | Select-Object -ExpandProperty ServerName

foreach ($DP in $DPs) {
    Write-InformationColored -MessageData "Now collecting information for $($DP)" -ForegroundColor Yellow -BackgroundColor Black -InformationAction Continue
    #Generate the query that collects the information:
    $Query = "select * from SMS_PackageStatusDistPointsSummarizer where State in ('1','2','3','7') and SourceNALPath like '%$DP%'"
    #Now Run collect the CIM Instances that match this criteria.
    $Failures = Get-CimInstance -ComputerName $SiteServer -Namespace "root\sms\site_$($SiteCode)" -Query $Query
    if($($Failures | Measure-Object).Count -gt 0) {
        Write-InformationColored -MessageData "The Distribution Point $($DP) HAS content distribution failures" -ForegroundColor Red -BackgroundColor Black -InformationAction Continue
        Write-InformationColored "      INSTALL_RETRYING counts on $($DP) is: $(($Failures | Where-Object {$_.State -eq 2} |  Measure-Object).Count) `
      INSTALL_PENDING counts on $($DP) is: $(($Failures | Where-Object {$_.State -eq 1} |  Measure-Object).Count) `
      INSTALL_FAILED counts on $($DP) is: $(($Failures | Where-Object {$_.State -eq 3} |  Measure-Object).Count)  `
      CONTENT_UPDATING counts on $($DP) is: $(($Failures | Where-Object {$_.State -eq 7} |  Measure-Object).Count)" -InformationAction Continue -ForegroundColor Red -BackgroundColor Black
        foreach ($Failure in $Failures) {
            
            Write-InformationColored -MessageData "             Package in INSTALL_RETRYING state on $($DP): $($Failure.PackageID) - ErrorID: $(switch($Failure.State){1 {"INSTALL_PENDING"};2 {"INSTALL_RETRYING"};3 {"INSTALL_FAILED"};7 {"CONTENT_UPDATING"}})" -InformationAction Continue
        }
    }
    else{
        Write-InformationColored -MessageData "The Distribution Point $($DP) DOES NOT HAVE content distribution failures" -ForegroundColor Green -BackgroundColor Black -InformationAction Continue
    }
}
