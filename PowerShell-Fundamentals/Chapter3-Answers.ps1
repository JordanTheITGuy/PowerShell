<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK

.NOTES
          FileName: Chapter3-Answers.ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-04
          Modified: 2019-06-04

          Version - 1.0.0 - (2019-06-04)
#>



##################################################################
#Region Exercise 3.5.1 

#Question 1 - Using what you have learned – Determine what day of the week today is. If the day of the week is Monday, Wednesday or Friday, then calculate 10 + 10 and write a message back to the screen that includes the result. 

#Solution 1
if(((Get-date).DayOfWeek -eq "Monday") -or ((Get-Date).DayOfWeek -eq "Wednesday") -or ((Get-Date).DayOfWeek -eq "Friday")){
    $Answer = 10 + 10
    Write-Output -InputObject $Answer
}

#Question 2 – Using What you have learned - Determine what day of the week today is. If the day of the week is Tuesday or Thursday calculates 20 – 10 and write a message back to the screen that includes the result. 

#Solution 1

if(((Get-date).DayOfWeek -eq "Tuesday") -or ((Get-Date).DayOfWeek -eq "Thursday")){
    $Answer = 20 - 10
    Write-Output -InputObject $Answer
}

#Question 3 – Using what you have learned - Combine the  statements above to create an if, and elseif statement that calculates either 10 + 10 or 20 – 10 based on what day of the week it is and returns the result. 

#Solution 1

if(((Get-date).DayOfWeek -eq "Monday") -or ((Get-Date).DayOfWeek -eq "Wednesday") -or ((Get-Date).DayOfWeek -eq "Friday")){
    $Answer = 10 + 10
    Write-Output -InputObject $Answer
}

elseif(((Get-date).DayOfWeek -eq "Tuesday") -or ((Get-Date).DayOfWeek -eq "Thursday")){
    $Answer = 20 - 10
    Write-Output -InputObject $Answer
}

#Question 4 – Using what you have learned determine what month is, and if it’s an even month or odd month perform a different action of your choice. 

#Solution 1

if($((((Get-Date).Month)/2).GetType()).Name -eq "Double"){
    "Odd month"
}
else{
    "Even Month"
}

#Solution 2

$today = Get-date
if($today.Month % 2 -eq 0){
    "It's an Even month"
}
else{
    "It's an Odd Month"
}

#endregion Exercise 3.5.1
##################################################################

##################################################################
#Region Exercise 3.5.2

#Question 1 – Using what you have learned – Retrieve todays date and store it in an object. Using the object retrieve yesterday’s date. Then retrieve all files stored in C:\Resources on the host machine and find all files that were modified before yesterday. Find all files that were modified AFTER yesterday. 

#Solution 1
$Today = Get-Date
$Yesterday = $today.AddDays(-1)
$Files = Get-ChildItem C:\scripts -Recurse -File
foreach($File in $Files){
    if($File.LastWriteTime -gt $Yesterday){
        $File.FullName
    }
}

#Solution 2
$Today = Get-Date
$Yesterday = $today.AddDays(-1)
Get-ChildItem C:\scripts -Recurse -File | ForEach-Object {if($_.LastWriteTime -gt $Yesterday){$_.FullName}}

#Solution 3
Get-ChildItem C:\scripts -Recurse -File | ForEach-Object {if($_.LastWriteTime -gt $($(Get-Date).AddDays(-1))){$_.FullName}}


#Question 2 – Using what you have learned – retrieve all files in the resources folder. If there are any files with a *.PS1 ending what operator would you use to find them? Use this operator to find all of them and store them in a variable.

#Solution 1 - YES this works - but this isn't the real answer

Get-ChildItem -Path C:\scripts -filter "*.PS1"

#Solution 2

$FileList = Get-ChildItem -Path C:\scripts -Recurse -File
$PS1FILES = @()
foreach($File in $FileList){
    if($file.Name -like "*.PS1")
    {
        $PS1FILES += $File.FullName
    }
}
$PS1FILES

#Solution 3

$Files = @()
Get-ChildItem -Path "C:\scripts" -Recurse -File | ForEach-Object{if($_.Name -like "*.PS1"){$Files += $_.FullName}}


#endregion Exercise 3.5.2
##################################################################

##################################################################
#Region Exercise  3.5.3

#Question 1 - Write a short script that checks if a service is running similar to the one in Example  45 but if the service has not started after 10 seconds attempt to start the service and then continue the loop. 

#Solution 1

While ((Get-service -name "XboxNetApiSvc").Status -eq "Stopped"){
    Start-Service -Name "XboxNetApiSvc"
    Write-Output -InputObject "The service wasn't running so we tried to start it sleeping 10 seconds"
    Start-Sleep -Seconds 10
}

#Note this will run forever as the service may not ever propely start

#Question 2 - Write a while loop that checks if it’s time to go home yet every five minutes until it’s time to go home.  – (5:00 PM)

While((Get-Date).Hour -lt '17'){
    Write-Output -InputObject "It's not time to go home yet wait five minutes"
    Start-Sleep -Seconds $(60*5)
}

#Question 3 - Choose your own adventure

#endregion Exercise 3.5.3
##################################################################

##################################################################
#Region Exercise 3.5.4

#Question 1 - Write a Do Until loop that looks for Christmas day start from today and work your way till Christmas. Make sure you put something back to the screen to track its process using either write-output, write-host, or write-verbose. – Make sure it can be re-run without crashing

#Solution 1
$counter = 0
Do{
    $StartDate = Get-Date -Hour 12 -Minute 00 -Second 00 -Millisecond 00
    $Christmas = Get-Date  -Hour 12 -Minute 00 -Second 00 -Millisecond 00 -Month 12 -Day 25
    $counter++
    if($StartDate.AddDays($counter) -eq $Christmas){
        Write-Output -InputObject "Congratulations you found christmas its $($Counter) days away"
    }
    elseif($StartDate.AddDays($counter) -ne $Christmas) {
        Write-Output -InputObject "It's not Christmas yet that's sad its - $($StartDate.AddDays($counter))"
    }
}
until ($StartDate.AddDays($counter) -eq $Christmas)

#Question 2 - Write a Do until loop that Does something until 60 seconds have passed. The something that is done can be anything. – Make sure it can be re-run without crashing. 

do{
    if(-not ($StartTime)){
        Write-Output -InputObject "We ran this before zeroing out"
        $StartTime = Get-Date
        $EndTime = $StartTime.AddSeconds(10)
    }
    if((Get-Date).AddSeconds(-10) -gt $StartTime)
    {
        Write-Output -InputObject "We ran this before zeroing out"
        $StartTime = Get-Date
        $EndTime = $StartTime.AddSeconds(10)
    }
    Write-Output -InputObject "Well hello there"
}
until((Get-Date) -ge $EndTime)

#Question 3 – Using what you’ve learned see if you can write something that stops a service and checks the status of the service until it’s stopped and bonus points if you re-start the service. 

#Solution 1
do{
    if((Get-Service -Name "wuauserv").Status -eq "Running"){
        Stop-Service -Name "wuauserv" -Force
        Write-Output -InputObject "Stopping the WUAService"
    }
}
until((Get-Service -Name "wuauserv").Status -eq "Stopped")


#endregion Exercise 3.5.4
##################################################################

##################################################################
#Region Exercise 3.5.5

#Question 1 - Using the for loop add a letter to a string and send the string back to the screen using either write-host, write-output or write-verbose

#solution 1

For ($i=0; $i -lt 5; $i++){
    if($i -le 1){
        $BaseString = "The First Pass"
        $EndString = $BaseString + " A"
        Write-Output -InputObject "$($Endstring)"
    }
    elseif($i -ge 1){
        $EndString = $EndString + " A"
        Write-Output -InputObject "$($Endstring)"
    }
}

#Question 2 - Using the “for” loop the following code snippet create a password generator that will create a 10-character long password:


#solution 1

for ($i=0; $i -lt 10; $i++){
    $Char = -join ((65..90) + (97..122) | Get-Random | ForEach-object {[char]$_})
    $Password = $Password + $Char
}
$Password

#Solution 2 - Cheating
-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-object {[char]$_})

#Question 3 - Bonus exercise – Create a hash table with each person in the rooms name and a unique password for them. 

#Solution
$IDInfo = @()
$Hash1 = @{UserName = "Jordan";password = $(-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-object {[char]$_}))}
$Hash2 = @{UserName = "Student1";password = $(-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-object {[char]$_}))}
$Hash3 = @{UserName = "Student2";password = $(-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-object {[char]$_}))}
$Teacher = New-Object -TypeName psobject -Property $Hash1
$student1 = New-Object -TypeName psobject -Property $Hash2
$student2 = New-Object -TypeName psobject -Property $Hash3
$IDInfo+=$Teacher
$IDInfo+=$student1
$IDInfo+=$student2

#endregion Exercise 3.5.5
##################################################################

##################################################################
#Region Exercise 3.5.6
#Question 1 – Using a ForEach loop check for every day in the month of December to see if that day is Christmas. 

#Solution 1 - TryHardMode
$daysinDecember = @(1..$([DateTime]::DaysInMonth(2019, 12)))
ForEach($Day in $daysinDecember){
    if($Day -eq "25"){
        Write-Output -InputObject "It's christmas finally!"
    }
    else {
        Write-Output -InputObject "It's not christmas"
    }
}

#Solution 2 - Not So Try Hard
$daysinDecember = @(1..31)
ForEach($Day in $daysinDecember){
    if($Day -eq "25"){
        Write-Output -InputObject "It's christmas finally!"
    }
    else {
        Write-Output -InputObject "It's not christmas"
    }
}

#Question 2 - Using a ForEach loop retrieve the full file patch for all items in the ‘resources’ folder. 

#Solution 1
$Files = Get-ChildItem -Path C:\scripts -File
foreach($File in $Files){
    Write-Output $File.FullName
}

#Question 3 - Using a ForEach loop count the number of files in the resources folder (You can also do this with count but what if you encounter something you can’t count?) 

#solution 1

$Files = Get-ChildItem -Path C:\scripts -File
$counter = 0
foreach($File in $Files){
    $counter++
}

#Question 4 - Using a ForEach loop perform the bonus exercise from the last section and create a password and username in a hash table for each person in the room and store the data in a PSCustom object.

#Solution 1

$Users = @("Jordan","Student1","Student2","Studen3")
$IDInfo = @()
foreach($user in $Users){
    $Hash = [ordered]@{
        UserName = $user
        password = $(-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-object {[char]$_}))
    }
    $user = New-Object -TypeName psobject -Property $Hash
    $IDInfo+=$user
}

#endregion Exercise 3.5.6
##################################################################

##################################################################
#Region Exercise 3.5.7

#Question 1 - Using the PowerShell Pipeline get all files in C:\Resources and return their last write time. 

#solution 1
Get-ChildItem -Path C:\scripts -File -Recurse | ForEach-Object{Write-Output $_.LastWriteTime}

#Question 2 - Using the PowerShell Pipeline get all files in C:\Resources and only return the files that have .PS1 in the name. 

Get-ChildItem -Path C:\scripts -File -Recurse | ForEach-Object{if($_.Name -like "*.PS1"){Write-Output -InputObject $_.Name}}


#Question 3 – Using the PowerShell Pipeline and foreach-object Get all services that are running and return it

Get-Service | ForEach-Object {if($_.Status -eq "Running"){Write-Output -InputObject $_}}

#Question 4 - Using The PREVIOUS code section where you created an array of PSObjects pass the array of objects through the PowerShell pipeline and foreach-object in the pipeline return the password and user name. 

$IDInfo | ForEach-Object {Write-Output $_}

#endregion Exercise 3.5.7
##################################################################

##################################################################
#Region Exercise 3.5.8

#Question 1 - Using the Where-object statement check to see if today is Christmas. 

#solution 1
Get-Date -Day 25 -Month 12 | Where-Object {($_.month -eq 12) -and ($_.Day -eq 25)}

#Example FORCED working
Get-Date -Day 25 -Month 12 | Where-Object {($_.month -eq 12) -and ($_.Day -eq 25)}

#Question 2 - Using the Where-Object statement get a listing of all stopped services 

Get-Service | Where-Object {$_.Status -eq "stopped"}

#Question 3 - Using the Where-Object statement return a specific stopped service – and then start that service. 
Get-Service | Where-Object {($_.Status -eq "stopped") -and ($_.Name -eq "Wmansvc") } | Start-Service

#Question 4 - Using the where-object and the PSObject hash table you created earlier ONLY return JORDAN and his password.
$IDInfo | Where-Object {$_.UserName -eq "Jordan"}

#endregion Exercise 3.5.8
##################################################################
