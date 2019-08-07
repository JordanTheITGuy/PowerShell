Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
$Drive = (Get-PSDrive -PSProvider CMSite).Name
Set-Location $($Drive + ":")
$List = [System.Collections.Generic.List[object]]::new()
$Servers = Get-CMDistributionPointInfo | ForEach-Object{if($_.NalPath -in $(Get-CMDistributionPointDriveInfo | Where-Object {$_.Drive -eq "C"}).NalPath){if(!(test-path -Path "\\$($_.ServerName)C$\NO_SMS_ON_DRIVE.SMS")){$_.ServerName}}}
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
}