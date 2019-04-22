<#
.Synopsis 
    Checks if a reboot is required on the current server

.Description
    Checks for a pending reboot using the three most common options fo re reboot flags being set. 

.Link
    Researched from http://ilovepowershell.com/2015/09/10/how-to-check-if-a-server-needs-a-reboot/

.Notes
    FileName:    Test-RebootRequired.PS1
    Author:      Jordan Benzing
    Contact:     @JordanTheItGuy
    Created:     2019-04-22
    Updated:     2019-04-22

    Version 0.0.0 (2019-04-22) - Source Code was copied from a website Will update and modify to fit within existing methods

#>


function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}