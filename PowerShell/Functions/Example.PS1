[cmdletbinding()]
param(
    [Parameter()]
    [string]$Hello
)
$String = $MyInvocation.BoundParameters.Keys
Write-Verbose -Message "$STring" -Verbose
