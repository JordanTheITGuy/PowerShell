function Get-DistributionPoints {
    <#
    .SYNOPSIS
        Input the SCCM site code and server name to remotely get the distribution point names in an environment.
    .DESCRIPTION
        Created to allow you to get the Distribution points in an environment from SCCM without needing to load the CM Module and without needing to be on the 
        SCCM Site server. As long as WINRM works this works. Can be used dynamically in a lot of different scripts for doing health checks. 

    .LINK

    
    .NOTES
              FileName: Get-DistributionPoints.ps1
              Author: Jordan Benzing
              Contact: @JordanTheItGuy
              Created: 2019-11-29
              Modified: 2019-11-29
    
              Version - 0.0.0 - (2019-11-29)
    
              COMPLETE:
                   Function Main Goal: Get list of distribution points.
                   
    
    .EXAMPLE
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = "Enter the Site Code", Mandatory = $true )]
        [string]$SiteCode,
        [Parameter(HelpMessage = "Enter the Site Server Name" , Mandatory = $true )]
        [string]$SiteServer
    )
    begin{
        try{
            if(!(Test-NetConnection -ComputerName $SiteServer -CommonTCPPort WINRM))
            {
                throw "Could not establish a connection over the WINRM port for WMI access"
            }
        }
        catch{
            Write-Error -Message "$($_.Exception.Message)"
        }

    }
    process{
        $DPS = Get-CimInstance -ComputerName $SiteServer -Namespace "root\sms\site_$($SiteCode)" -query "SELECT * FROM SMS_SystemResourceList WHERE RoleName='SMS Distribution Point'" | Select-Object -ExpandProperty ServerName
        $DPS
    }
}
