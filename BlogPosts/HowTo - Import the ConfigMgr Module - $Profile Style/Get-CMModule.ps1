function Get-CMModule
#This application gets the configMgr module
{
    [CmdletBinding()]
    param(
    [Parameter(HelpMessage = "Enter the Site Code you would like to connect to" )]
    [string]$SiteCode = "YOURSITECODEHERE",
    [Parameter(HelpMessage = "Enter the name of the site server you would like to connect to")]
    [string]$SiteServer = "YOURSITESERVERHERE"
    )
    Try
    {
        Write-Verbose "Attempting to import SCCM Module"
        #Retrieves the fcnction from ConfigMgr installation path. 
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        Write-Verbose "Succesfully imported the SCCM Module"
        $initParams = @{}
        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer @initParams
        }
    }
    Catch
    {
        Throw "Failure to import SCCM Cmdlets."
    } 
}
