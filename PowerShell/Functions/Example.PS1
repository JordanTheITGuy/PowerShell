[cmdletbinding()]
param(
    [Parameter()]
    [string]$Hello
)
function get-TSxNetworkConfiguration{
    [CmdletBinding()]
    param()
    $Information = Get-NetIPConfiguration | Select-Object InterfaceAlias,IPv4Address,IPv6Address,NetProfile,DNSServer
    $NetworkInfo = @()
    ForEach($Interface in $Information){
        $Hash = @{
            InterfaceName = $Interface.InterfaceAlias
            IPv4Address = $Interface.IPv4Address
            IPv6Address = $Interface.IPv6Address
            NetProfile = $Interface.NetProfile.Name
            DNSServer = $Interface.DNSServer.ServerAddresses
        }
        $Item = New-Object -TypeName psobject -Property $Hash
        $NetworkInfo += $Item
    }
    return $NetworkInfo
}