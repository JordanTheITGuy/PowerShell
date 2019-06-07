<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK
    

.NOTES
          FileName: Chapter7-Answers.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-06
          Modified: 2019-06-06

          Version - 1.0.0 - (2019-06-06)



.Example

#>

##################################################################
#Region Exercise 7.3.1
<#
Question 1 – Take a moment to look through some items in the PowerShell Gallery. If you do not yet have an account please create one at this time. Use the Space below to write down any modules you find that are interesting. 

Some of the PowerShell Examples that I find interesting are:
	PSWindowsUpdate
	PSLogging
	CMOperations
	OSDBuilder
	SCCM-Probres
	CMHealthCheck
#>

#Question 2 – Using what you have learned on CLIENT01 – install the PSWindowsUpdate PowerShell module from the PowerShell Gallery and investigate the commands.

#Soltuion 1

Install-Module PSWindowsUpdate -Force
$CommandList = Get-Command -Module PSWindowsUpdate
foreach($Command in $CommandList){
    Get-help $Command.Name
}

#Solution2

Install-Module PSWindowsUpdate -Force
Get-Command -Module PSWindowsUpdate | ForEach-Object {Get-Help $_.Name}

#Question 3 Using what you have learned on CLIENT02 – Install the SQL PowerShell Module from the PowerShell Gallery

Install-Module -Name SqlServer

#endregion Exercise 7.3.1
##################################################################

##################################################################
#Region Exercise 7.3.2

#Question 1 – Using what you have learned create a new PowerShell manifest using the pre-defined PowerShell Template

#Solution 1

New-ModuleManifest -Path C:\Users\student\desktop\CMExample.PSD1

#Question 2 – Using what you have learned create a PowerShell Module file that has some of the functions you previously have written or new ones stored in it. 
#See - https://github.com/JordanTheITGuy/CMOperations - for example code. 

#Question 3 – BONUS QUESTION – Using what you have learned upload the PowerShell module to the PowerShell Gallery and using the install-module command install the module on CLIENT01

Publish-Module -Name "ModuleName" -NuGetApiKey "YourAPIKeyHere"

#Note if you get an error you may have to update your NUGET pacakge this sometimes requires a reboot and sometimes displays an error with updating even if there is no actual errror/warning.

#endregion Exercise 7.3.2
##################################################################

