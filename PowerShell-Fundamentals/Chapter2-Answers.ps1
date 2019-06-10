<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK



.NOTES
          FileName: Chapter2-Answers.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-03
          Modified: 2019-06-03

          Version - 1.0.0 - (2019-06-03)


          TODO:
#>


##################################################################
#Region Exercise 2.8.1

Get-Help -Name 'Get-Content'
Get-Help -Name 'Get-Module'
Get-Help -Name 'Get-Command'

#endregion Exercise 2.8.1
##################################################################

##################################################################
#Region Exercise 2.8.2

#Question 1 – Create a variable “$Integer” that contains the integer 25 without using the quotation symbols and implied logic. 

$Integer = 25

#Question 2 – Using a hard CAST of the variable create an integer object that contains the number 50 in the variable $Integer2

[int]$Integer2 = "50"

#Question 3 – Using the “GetType” method prove that both variables are in fact integers. 

$Integer.GetType()
$Integer2.GetType()
$Integer + $Integer2

#Question 4 – BONUS QUESTION Using the “Get” commands from earlier on in the lesson see what other types of data you can store in a variable.

$Item1 = Get-Help -Name 'Get-Content'
$Item2 = Get-Help -Name 'Get-Module'
$item3 = Get-Help -Name 'Get-Command'

$Item1.GetType()
$Item2.GetType()
$Item3.GetType()

#endregion Exercise 2.8.2
##################################################################

##################################################################
#region Excercise 2.8.3
#Question 1 - Using the Substring command retrieve only the word A
$Example1 = "A string of Text"
$Example1.Substring(0,1)

#Question 2 - Using the Substring command below retrieve only the word ‘Text’
$Example1 = "A string of text"
#We know that TEXT is 4 letters - So we need the LAST four - we know that LENGTH gives us
#The length of the string in a variable
#We know when we use substring we either are creating a starting point and then taking everything
#To the right of it OR we are taking a startiing point , a distance away from that starting point.
$Example1.Substring($Example1.Length - 4)

#Question 3
<#
A good example of this would be to find all fo the PS1 files in a directory or to find all of the TXT
files in a directory CSV etc. 
#>

#Practical Examples
#Some cmdlets provide filters attached to them as used below some however do not you can use
#certain things like Where-Object to filter things you can also use substring to evaluate things
#Alternatively you may want to use it to make changes to a specific substring

Get-ChildItem -Path "C:\Temp" -Filter *.TXT
Get-ChildItem -Path "C:\temp" | ForEach-Object {$_.FullName.Substring($_.FullName.Length -3)}

#endregion Excercise 2.8.3
##################################################################

##################################################################
#region Exercise 2.8.4

#Question 1 – Using String concatenation please combine the following strings. 
$String1 = "Your Dog"
$String2 = "is sitting on the couch"

#Solution 1

$String3 = $string2 + " " + $String1
$String3
$String3 = $null

#Soltuion 2

$String3 = "$($string2) $($String1)"
$String3
$String3 = $null

#Solution 3

$("$($string2) $($String1)")


#Question 2 – Using string concatenation please combine the following strings.

#Solution 1

$String3 = $string2 + " " + $String1
$String3
$String3 = $null

#Soltuion 2

$String3 = "$($string2) $($String1)"
$String3
$String3 = $null

#Solution 3

$("$($string2) $($String1)")

<#Question 3 – BONUS QUESTION
#Using what you have learned extract and swap the words “grey” and “blue” in the following sentence. 

$StartingString = “The house is grey and the sky is blue”

Please do this WITHOUT creating variables like:
$Grey = “Grey” 
$Blue = “blue”
Instead generate the value of “grey” by “extracting” the word from the string. 
#>

$StartingString = "The house is grey and the sky is blue"

#Solution 1
$EndingString = "$($StartingString.Substring(0,13))$($StartingString.Substring($StartingString.Length-4))$($StartingString.Substring(17,16))$($StartingString.Substring(13,5))"

#Solution 2
$EndingString = "$($StartingString.Substring(0,13)) blue$($StartingString.Substring(17,16))grey"

#Solution 3
$StartingString = "The house is grey and the sky is blue"
$EndingString = $StartingString.Replace("grey","1")
$EndingString = $EndingString.Replace("blue","2")
$EndingString = $EndingString.Replace("1","blue")
$EndingString = $EndingString.Replace("2","grey")

#Solution 4
"$($($StartingString.Substring(0,17)).Replace("grey","blue"))$($($StartingString.Substring(17)).Replace("blue","grey"))"






#endregion Exercise 2.8.4
##################################################################

##################################################################
#Region Exercise 2.8.5

#Question 1 - Create an array with your favorite cereals in it

#Solution 1
$Cereals = @()
$Cereals += "Frosted Flakes"
$Cereals += "Lucky Charms"
$Cereals += "Fruit Loops"

#Solution 2
$Cereals = @("Frosted Flakes" , "Lucky Charms" , "Fruit Loops")

#Solution 3
$Cereals = New-Object System.Collections.ArrayList
$Cereals.Add("Frosted Flakes")
$Cereals.Add("Lucky Charms")
$Cereals.Add("Fruit Loops")

#Solution 4
$Cereals = New-Object 'Collections.Generic.List[string]'
$Cereals.Add("Frosted Flakes")
$Cereals.Add("Lucky Charms")
$Cereals.Add("Fruit Loops")

#Question 2 - Remove one of your favorite cereals

#Solution 1
$Cereals = $Cereals | Where-Object {$_ -ne "Lucky Charms"}

#Solution 3
$Cereals = New-Object System.Collections.ArrayList
$Cereals.Remove("Frosted Flakes")
$Cereals.Remove("Lucky Charms")
$Cereals.Remove("Fruit Loops")

#Solution 4
$Cereals = New-Object 'Collections.Generic.List[string]'
$Cereals.Remove("Frosted Flakes")
$Cereals.Remove("Lucky Charms")
$Cereals.Remove("Fruit Loops")

#Question 3 – Add an additional cereal to the array 
$Cereals = @()
$Cereals += "Frosted Flakes"
$Cereals += "Lucky Charms"
$Cereals += "Fruit Loops"

#Question 4 - Bonus Question - Bonus Script – Using Get-ChildItem and foreach-object create an array with ALL of the file names in the resources folder. – There are several ways to do this but for the purpose of this exercise we are looking that when you get the type of the object it should return an object of type ARRAY and not ‘SystemObject’.

#Solution 1 - > Not correct -> TECHNICALLY WORKS -> Not Correct
$Files = @()
$Files = Get-ChildItem C:\temp | Select-Object Name

#Solution 2 - > CORRECT
$Files = @()
Get-ChildItem -Path "C:\temp" | ForEach-Object {$Files += $_.Name}

#Solution 3 -> Kinda Correct
$FileNames = New-Object 'Collections.Generic.List[string]'
Get-ChildItem -Path "C:\scripts" | ForEach-Object {$FileNames.Add($_.Name)}
$FileNames.GetType()

#endregion Exercise 2.8.5
##################################################################

##################################################################
#Region Exercise 2.8.6

#Question 1 – Create an ORDERED hash of information about a cereal including the following properties – Name (String), Healthy (True/False), Calories (Integer)

#Solution 1

$Hash = [ordered]@{
    Name=[string]"Lucky Charms"
    Healthy=[bool]$false
    Calories=[int]500
}

#Question 2 – Using What you learned convert the HASH into a generic PSObject

#Solution 1

$Cereal = New-Object -TypeName psobject -Property $Hash
#Prove that you typed it properly
$Cereal.Name.GetType()

#Question 3 – Using what you have learned create several more cereal hashes, convert them into PSObjects and add them to an array. 

#Solution 1

$Cereals = @()

$Hash = [ordered]@{
    Name=[string]"Cheerios"
    Healthy=[bool]$true
    Calories=[int]200
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals += $Cereal

$Hash = [ordered]@{
    Name=[string]"Lucky Charms"
    Healthy=[bool]$false
    Calories=[int]500
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals += $Cereal

$Hash = [ordered]@{
    Name=[string]"Frosted Flakes"
    Healthy=[bool]$false
    Calories=[int]300
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals += $Cereal

$Cereals

#Solution 2

$Cereals = New-Object System.Collections.ArrayList

$Hash = [ordered]@{
    Name=[string]"Cheerios"
    Healthy=[bool]$true
    Calories=[int]200
}
$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)

$Hash = [ordered]@{
    Name=[string]"Frosted Flakes"
    Healthy=[bool]$false
    Calories=[int]300
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)

$Hash = [ordered]@{
    Name=[string]"Lucky Charms"
    Healthy=[bool]$false
    Calories=[int]500
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)
$Cereals

#Solution 3
$Cereals = New-Object 'Collections.Generic.List[object]'

$Hash = [ordered]@{
    Name=[string]"Cheerios"
    Healthy=[bool]$true
    Calories=[int]200
}
$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)

$Hash = [ordered]@{
    Name=[string]"Frosted Flakes"
    Healthy=[bool]$false
    Calories=[int]300
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)

$Hash = [ordered]@{
    Name=[string]"Lucky Charms"
    Healthy=[bool]$false
    Calories=[int]500
}

$Cereal = New-Object -TypeName psobject -Property $Hash
$Cereals.Add($Cereal)
$Cereals

#Question 4 – BONUS QUESTION
#Bonus – using the logic from examples you have seen use the “where-object” cmdlet to return all cereals that are NOT healthy. Then, using the PowerShell Pipeline and the FOR-EACHOBJECT command create a new array of cereals that only includes the healthy cereals. 

$BADCereal = @()
$Cereals | Where-Object{$_.Healthy -eq $false} | ForEach-Object {$BadCereal += $_}

#endregion Exercise 2.8.6
##################################################################

##################################################################
#Region Exercise 2.8.7
#Question 1 – Using the below code snippet create an array that has Group-Name-01 -> 10 stored inside in a programmatic fashion. 

[string]$ADGroupName = "Group-Name-01"

#Solution 1 - This is a technically correct answer - its a weird way to do it. 
[string]$ADGroupName = "Group-Name-01"
[int32]$Number = $ADGroupName.Substring($ADGroupName.Length -2)
$Number1 = $Number
$Number++
$Number2 = $Number
$Number++
$Number3 = $Number
$Number++
$Number4 = $Number
$Number++
$Number5 = $Number
$Number++
$Number6 = $Number
$Number++
$Number7 = $Number
$Number++
$Number8 = $Number
$Number++
$Number9 = $Number
$Number++
$Number10 = $Number

$numbers = @($Number1,$Number2,$Number3,$Number4,$Number5,$Number6,$Number7,$Number8,$Number9,$Number10)
$ADGroups = @()
foreach($Number in $numbers){
    $NewADGroupName = "$($ADGroupName.Substring(0,$ADGroupName.Length -1))$($number.ToString($null))"
    $ADGroups += $NewADGroupName
}

#Solution 2 - MORE ADVANCED solution - But with a Gotcha - can you find it? 
[string]$ADGroupName = "Group-Name-01"
[int32]$Number = $ADGroupName.Substring($ADGroupName.Length -2)
$NumberList = @(1..10)
$ADGroupList = @()
foreach($Value in $NumberList){
    $NewNumber ="{0:00}" -f $($Number + $Value)
    $NewADGroupName = "$($ADGroupName.Substring(0,$ADGroupName.Length - 2))$($NewNumber)"
    $ADGroupList += $NewADGroupName
}

#Solution 3 

[string]$ADGroupName = "Group-Name-02"
$BaseName = $adgroupname.substring(0,$adgroupname.Length -2)
$NumberList = @(1..10)
$ADGroupList = @()
Foreach($number in $numberlist)
{
    $ADGrouplist += $BaseName + $("{0:00}" -f $Number)
}

#Solution 4
[string]$ADGroupName = "Group-Name-05"
[int32]$Number = $ADGroupName.Substring($ADGroupName.Length -2)
$CountMax = $Number + 10
$BaseName = $adgroupname.substring(0,$adgroupname.Length -2)
$ADGroupList = @()
For($Number;$Number -le $CountMax;$Number++)
{
    $ADGrouplist += $BaseName + $("{0:00}" -f $Number)
}


#Question 2 - BONUS Use get-childitem command to get the file size of all items in the virtual machine storage directory and calculate their total size in KB/MB/GB.

#Solution 1

Get-ChildItem -Path D:\VirtualMachines\ -Recurse -File | Select-Object Length | ForEach-Object {$total = $_.Length + $total};$total/1GB
$total/1KB
$total/1MB



#endregion Exercise 2.8.7
##################################################################

##################################################################
#Region Exercise 2.8.8


#Question 1 – Figure out what day of the week it was for the first day of every month of the year

#Solution 1
#You have to do this manually for every month of the year
(Get-date -day 1).DayofWeek
(Get-date -day 1 -month 1).DayofWeek

#Solution 2
#Set the month and then use a WHILE Loop to calculate it out - You may or may not know this one.

$Month = 1;while($month -ne '13'){(Get-Date -Month $Month -Day 1).DayofWeek;$Month++}


#Question 2 – Figure out what day of the week it was for the 15th day of the month for the current year.

#solution 1

#Manually Get each one

(Get-date -day 15).DayofWeek
(Get-date -day 15 -month 1).DayofWeek

#Solution 2
#Get the day of the week for the 15th of every month
$Month = 1;while($month -ne '13'){(Get-Date -Month $Month -Day 15).DayofWeek;$Month++}

#Question 3 – BONUS QUESTION – Write a one liner that determines if today is Christmas.

if((Get-date).Month -eq '12' -and (Get-Date).day -eq '25'){write-host "It's Christmas!"}else{write-host "It's not christmas :("}

#Question 4 – BONUS QUESTION – Find Thanksgiving – (US Holiday – Third Thursday in November)

$StartingPoint = $((Get-Date -day 1 -month 11))
switch ($($StartingPoint.DayofWeek)){Friday {$StartingPoint = $StartingPoint.AddDays(6)}; Saturday {$StartingPoint = $StartingPoint.AddDays(5)};Sunday {$StartingPoint = $StartingPoint.AddDays(4)}; Monday {$StartingPoint = $StartingPoint.AddDays(3)};Tuesday {$StartingPoint = $StartingPoint.AddDays(2)}; Wednesday {$StartingPoint = $StartingPoint.AddDays(1)}; Thursday {$StartingPoint = $StartingPoint}}
$StartingPoint.AddDays(21)

#endregion Exercise 2.8.8
##################################################################


