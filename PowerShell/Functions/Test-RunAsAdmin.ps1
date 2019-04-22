<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Test-RunAsAdmin.ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-04-22
          Modified: 2019-04-22

          Version - 0.0.0 - (2019-04-22) - Script/Function works as intended.

          TODO:
               [X] Check if current user is running in Admin Context
               

.Example

#>
function Test-RunAsAdmin{
    [cmdletbinding()]
    param()
    begin{}
    process{
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if(!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
            return $false
        }
        return $true
    }
}