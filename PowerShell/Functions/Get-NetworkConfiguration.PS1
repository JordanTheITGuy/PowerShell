<#
.SYNOPSIS
    Function to get the network configuration of a NIC. Works against remote machines as well. 

.DESCRIPTION
    Function that gets network configuration of a server or workstation and prints it to the screen. This function can be invoked remotely against a remote machine by using 
    Invoke-Command -scriptblock ${Function:get-NetworkConfiguration}

.LINK
    https://github.com/JordanTheITGuy/ProblemResolution/tree/master/PowerShell/Functions

.NOTES
          FileName: Get-NetworkConfiguration.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-04-22
          Modified: 2019-04-22

          Version - 0.0.0 - (2019-04-22) - Functional Script
          Version - 0.0.1 - (2019-04-22) - Added in some exampels and noted its usage in other situations as a script block


          TODO:
               [ ] Get and Print network information about a device.

.Example
    . .\Get-NetworkConfiguration.PS1
    Get-NetworkConfiguration

.Example
    . .\Get-NetworkConfiguration.Ps1
    $NetworkConfiguration = (Invoke-Command -HideComputerName -ComputerName $ComputerName -ScriptBlock ${Function:get-PSDNetworkConfiguration} 

#>

[cmdletbinding()]
param()
begin{}
process{
    function get-NetworkConfiguration{
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
}