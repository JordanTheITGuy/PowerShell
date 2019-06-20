$computername = $env:COMPUTERNAME
For($i=0;$i -lt 10;$i++){
$Counter = Measure-Command{ get-WMIObject -Namespace "root\SMS" -Class "SMS_ProviderLocation" | foreach-object{ if ($_.ProviderForLocalSite -eq $true){$_.sitecode}}}
$Total = $Total + $Counter.Milliseconds
}

For($i=0;$i -lt 10;$i++){
    $Counter = Measure-Command{$(((Get-WmiObject -namespace "root\sms" -class "__Namespace").Name).substring(8-3))}
    $Total2 = $Total + $Counter.Milliseconds
    }
    $Total2/10