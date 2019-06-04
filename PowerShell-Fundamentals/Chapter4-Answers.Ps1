<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK

.Notes
          FileName: Chapter4-Answers.Ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-04
          Modified: 2019-06-04

          Version - 1.0.0 - (2019-06-04)

#>

##################################################################
#Region Exercise 4.3.1

#Question 1 – Review the  – Using the function “Write-TSXoutput” and what you have learned retrieve all of the services and return the name of each service that is running in Green and red if it’s stopped.

#Solution 1

Get-Service | ForEach-Object {if($_.Status -eq "Running"){Write-TsxOutPut -MsgLevel Success -Message $_.Name};if($_.Status -eq "Stopped"){Write-TsxOutPut -MsgLevel Warning -Message $_.Name }}

#endregion Exercise 4.3.1
##################################################################

##################################################################
#Region Exercise 4.3.2
#Question 1 - Using ANY of the previously described loop repeating loop methods, write a script that attempts to do something (Get a file name, etc.) – fails doing it, tries again and if it fails a second time, errors out. Your answer MUST include an -Error Action Silently Continue and -Error Action Continue

#solution 1

$PreviouslyAttempted = $false
Do{
    if($PreviouslyAttempted){
    Write-Output -InputObject "Warning we already tried once and failed now trying again without suppressing errors"
    Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction Stop
    $Complete = $true
    }
    Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction SilentlyContinue
    Write-Output -InputObject "We are trying to get it"
    $PreviouslyAttempted = $true
}
until($Complete)

#endregion Exercise 4.3.2
##################################################################

##################################################################
#Region Exercise 4.3.3

#Question 1 – Using a LOOP write a script that attempts to execute an action, write warning the first time it attempts and fails, and generate a terminating error on the second attempt.

#Solution

$PreviouslyAttempted = $false
Do{
    if($PreviouslyAttempted){
    Write-Output -InputObject "Warning we already tried once and failed now trying again without suppressing errors"
    Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction Stop
    $Complete = $true
    }
    $value = Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction SilentlyContinue
    Write-Output -InputObject "We are trying to get it"
    if(-not($value)){
        Write-Warning -Message "We did not manage to get it we will try again. "
    }
    $PreviouslyAttempted = $true
}
until($Complete)

#endregion Exercise 4.3.3
##################################################################

##################################################################
#Region Exercise 4.3.4
#Question 1 - Using the code from the previous exercise use the write-verbose cmdlet to write out a status update to the screen. An example of this is using writing out the number from the counting function using verbose instead of write-host.

#solution 

for($i=0;$i -lt 10;$I++){
    Write-Verbose -Message $i -Verbose
}

#endregion Exercise 4.3.4
##################################################################

##################################################################
#Region Exercise 4.3.5

#Question 1 - Using the write-debug command expand on the for loop from the write -error section and when the script errors the first time use write-Debug to prompt the user to see if they would like to try again or stop. 

#Solution 1 

$PreviouslyAttempted = $false
Do{
    if($PreviouslyAttempted){
    Write-Output -InputObject "Warning we already tried once and failed now trying again without suppressing errors"
    Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction Stop
    $Complete = $true
    }
    $value = Get-Item -Path C:\scripts\IDontExist.PS1 -ErrorAction SilentlyContinue
    Write-Output -InputObject "We are trying to get it"
    if(-not($value)){
        Write-Debug -Message "We did not manage to get it we will try again." -Debug
    }
    $PreviouslyAttempted = $true
}
until($Complete)

#endregion Exercise 4.3.5
##################################################################

##################################################################
#Region Exercise 4.3.6 
#Question 1 - Using a Try and Catch statement, evaluate if today is Christmas, and if it’s not catch and write verbose why. 

try{
    $today = Get-Date
    if((-not ($today.Month -eq "12")) -or (-not($today.Day -eq 25))){
        Write-Error -Message "ERROR - Today is NOT christmas" -ErrorAction Stop
    }
    else {
        Write-Verbose -Message "Today is the day it's christmas! Stop working on powershell and go enjoy christmas" -Verbose
    }
}
catch{
    Write-Verbose -Message "Today is not christamas so sad for you" -Verbose
}

#Question 2 - Using a try and catch statement use the ‘Test-NetConnection’ cmdlet to try and connect to port 3389 to Client01

try {
    Test-NetConnection -ComputerName Client01 -Port 3389 -ErrorAction Stop
}
catch {
    Write-Verbose -Message "The connection test failed below is the error message" -Verbose
    Write-Error -Message "$($_.Exception.Message)"
}

#Question 3 - Using a Try and catch statement try to ping Client01.

try {
    Test-Connection -ComputerName Client01 -ErrorAction Stop
}
catch {
    Write-Verbose -Message "The connection test failed below is the error message" -Verbose
    Write-Error -Message "$($_.Exception.Message)"
}

#Question 4 - Using a Try and catch statement try use test-netconnection cmdlet to DC01

try {
    if(-not(Test-NetConnection -ComputerName Client01)){
        Write-Error "Failed Test-NetConnection Command" -ErrorAction Stop
    }
}
catch {
    Write-Verbose -Message "The connection test failed below is the error message" -Verbose
    Write-Error -Message "$($_.Exception.Message)"
}

#endregion Exercise 4.3.6
##################################################################

