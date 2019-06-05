<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK
    

.NOTES
          FileName: Chapter6-Answers.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-05
          Modified: 2019-06-05

          Version - 1.0.0 - (2019-06-05)
.Example
#>


##################################################################
#Region Exercise 6.5.1

#Question 1 – Using what you have learned, create a simple function that when run returns the second Tuesday of the current month. 
#Solution 1

function Get-SecondTuesday {
    $CurrentMonth = $(Get-Date).Month
    switch ($(Get-Date -Month $CurrentMonth -Day 1).DayOfWeek){
        Sunday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(9)}
        Monday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(8)}
        Tuesday {$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(7)}
        Wednesday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(13)}
        Thursday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(12)}
        Friday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(11)}
        Saturday{$SecondTuesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(10)}
    }
    $SecondTuesday 
}
Get-SecondTuesday

#Question 2 – Using what you have learned create a simple function that when run returns the second Wednesday for a given month. 

#Solution - 1 
function Get-SecondWednesday {
    $CurrentMonth = $(Get-Date).Month
    switch ($(Get-Date -Month $CurrentMonth -Day 1).DayOfWeek){
        Sunday {$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(10)}
        Monday {$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(9)}
        Tuesday {$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(8)}
        Wednesday{$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(14)}
        Thursday{$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(13)}
        Friday{$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(12)}
        Saturday{$SecondWednesday = (Get-Date -Month $CurrentMonth -Day 1).AddDays(11)}
    }
    $SecondWednesday 
}
Get-SecondWednesday

#Question 3 – Using what you have learned create a simple function that gathers converts file size into KB/MB/GB using math.
#Solution 1
function Get-VMFolderSize{
    Get-ChildItem -Path D:\VirtualMachines -Recurse -File | Select-Object Length | ForEach-Object {$total = $_.Length + $total}
    Write-Output -InputObject "Size in GB is: $($total/1GB) GigaBytes"
    Write-Output -InputObject "Size in MB is: $($total/1MB) MegaBytes"
    Write-Output -InputObject "Size in KB is: $($total/1KB) KiloBytes"
}
Get-VMFolderSize
#endregion Exercise 6.5.1
##################################################################

##################################################################
#Region Exercise 6.5.2

#Question 1 – Using what you have learned create an advanced function that when run with the -Verbose parameter writes output to the screen.

function write-VerboseExample {
    [CmdletBinding()]
    param()
    Write-Verbose -Message "This is a message"
}

write-example -Verbose

write-example
#NOTE: Your answer should ONLY write a message if the verbose flag is triggered like above.

#Question 2 – Using what you have learned create an advanced function that when run with the -Debug Parameter outputs information to the screen and executes the debug command. 

function write-DebugExample {
    [CmdletBinding()]
    param()
    Write-Verbose -Message "This message always displays" -Verbose
    write-Debug -Message "This message only displays if the flag for debuging was called"
}
write-DebugExample 
write-DebugExample -Debug

#endregion Exercise 6.5.2
##################################################################

##################################################################
#Region Exercise 6.5.3

#Question 1 – Using what you have learned create an advanced function that accepts a file name and PATH parameter to retrieve a file and specific information you are interested in.

#solution 1
function Get-Fileinfo {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Enter the path to a file you would like to gather information about")]
        [string]$Path
    )
    try{
        if(Test-Path -Path $Path){
            $Information = Get-Item -Path $Path -ErrorAction Stop | Select-Object Name,FullName,LastAccessTime,LastWriteTime,Length
            Return $Information
        }
        else{
            throw
        }
    }
    catch{
        Write-Error -Message "Something went wrong attempting to access the file"
    }    
}
Get-Fileinfo -Path C:\scripts\RandomFunctions.ps1
Get-Fileinfo -Path C:\scripts\SomethingDoesntexist.PS1

#Question 2 – Using what you have learned create an advanced function that accepts a string message and an integer for the number of repeats. Based on the number of repeats write the message to the screen a specific number of times. 

#Solution 1
function write-ExampleRepeat {
    [CmdletBinding()]
    Param(
        [Parameter(HelpMessage = "Enter the number of times you would like the message to repeat",Mandatory=$true)]
        [Int32]$RepeatCount,
        [Parameter(HelpMessage = "Enter the message you would like to be displayed",Mandatory=$true)]
        [string]$Message
    )
    for($i=0;$i -lt $RepeatCount;$i++){
        Write-Verbose -Message "$($Message)" -Verbose
    }
}
write-ExampleRepeat -RepeatCount 2 -Message "We are going to write this message a bunch of times"

#Question 3 – BONUS QUESTION In certain scenario’s you may want certain parameters to only be applicable if another parameter was already used. These are called “PARAMETER SETS” – Research how Parameter sets work and create a function that if the parameter “Enforce” is called then a second parameter of your choosing becomes required. 

#solution 1
function write-ExampleParamSet {
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        [Parameter(HelpMessage = "The first message in the block",Mandatory=$true)]
        [string]$Message1,
        [Parameter(HelpMessage = "The second message in the block",ParameterSetName="Option1",Mandatory=$true)]
        [string]$Message2,
        [Parameter(HelpMessage = "This swich requires the second message.",ParameterSetName="Option1")]
        [switch]$RequireMessage2
    )
    Write-Verbose -Message "$($Message1)" -Verbose
    if($RequireMessage2){
        Write-Verbose -Message "$($Message2)" -Verbose
    }
}
write-ExampleParamSet -Message1 "Something" -RequireMessage2
write-ExampleParamSet -Message1 "Something else"
#endregion Exercise 6.5.3
##################################################################

##################################################################
#Region Exercise 6.5.4

#Question 1 – Using what you’ve learned, take all of the functions you have previously written store them in a single PS1 file and using the dot sourcing method load them into memory and run the functions. 

#endregion Exercise 6.5.4
##################################################################