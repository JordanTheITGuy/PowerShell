#Option 1 - Assumes the ConfigMgrModule is available for use
Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
$Drive = (Get-PSDrive -PSProvider CMSite).Name
Set-Location $($Drive + ":")
$List = [System.Collections.Generic.List[object]]::new()
$Servers = Get-CMDistributionPointInfo | Select-Object -ExpandProperty ServerName
ForEach($Server in $Servers){
    $TimeZone = Invoke-Command -ComputerName $Server -ScriptBlock {Get-TimeZone}
    $CurrentTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), "$($TimeZone.ID)")
    $Hash = [ordered]@{
        ServerName = $Server
        CurrentTime = $Currenttime
        TimeZone = $TimeZone.DisplayName
    }
    $Item = New-Object -TypeName PSobject -Property $Hash
    $List.Add($Item)
    return $List
}

#Function for getting the current time of all Distribution points.
function Get-DPCurrentTime{
    [CmdletBinding()]
    param(
    [Parameter(HelpMessage = "Enter the name of the ConfigMgr Server",Mandatory = $true)]
    [string]$ConfigMgrServer,
    [Parameter(HelpMessage = "Enter the ConfigMgr Site Server", Mandatory = $true)]
    [string]$SiteCode
    )
    begin{}
    process{
        $DPList = Get-WmiObject -ComputerName $ConfigMgrServer -Namespace root\sms\site_$SiteCode -Query "select distinct ServerName from sms_distributionpointInfo"
        $List = [System.Collections.Generic.List[object]]::new()
        ForEach($Server in $DPList){
            $TimeZone = Invoke-Command -ComputerName $Server.ServerName -ScriptBlock {Get-TimeZone}
            $CurrentTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), "$($TimeZone.ID)")
            $Hash = [ordered]@{
                ServerName = $Server.SERVERNAME
                CurrentTime = $Currenttime
                TimeZone = $TimeZone.DisplayName
            }
            $Item = New-Object -TypeName PSobject -Property $Hash
            $List.Add($Item)
        }
    return $List
    }
}

#Function for Getting the current time of a specific server
function Get-RemoteTime {
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = "The name of the remote computer")]
        [string]$ComputerName
    )
    $TimeZone = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-TimeZone}
    $Time = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Date}
    $CurrentTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(($Time), "$($TimeZone.ID)")
    return "The current time of the remote machine is: $($CurrentTime) it's TimeZone ID is: $($TimeZone.ID)"
}
