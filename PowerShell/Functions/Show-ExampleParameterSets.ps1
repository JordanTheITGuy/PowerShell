[CmdletBinding(DefaultParameterSetName='None')]
param(
    [parameter(HelpMessage="YourName",Mandatory=$false)]
    [string]$YourName,
    [Parameter(ParameterSetName="Share",HelpMessage="Switch to determine if you will like or share this TrueSec Minute",Mandatory=$false)]
    [switch]$SocialMedia,
    [Parameter(ParameterSetName="Share",HelpMessage="Will you like this TrueSec Minute?",Mandatory=$true)]
    [ValidateSet('true','false')]
    [string]$Like,
    [Parameter(ParameterSetName="Share",HelpMessage="Will you share this TrueSec Minute?",Mandatory=$true)]
    [ValidateSet('true','false')]
    [string]$Share
)
if($SocialMedia)
{
    if(($Share -ieq "true") -and ($Like -ieq "true"))
    {
        Write-Output $("$YourNAme YOU ARE THE BEST EVER!!!")
    }
    if(($Share -ine "true") -or ($Like -ine "true"))
    {
        Write-Output $("$YourName well, you're still pretty cool")
    }
}
elseif (($YourName) -and (!($SocialMedia)))
{
    Write-Output $("You only put your name in $YourName")    
}