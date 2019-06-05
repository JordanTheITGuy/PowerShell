<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK

.NOTES
          FileName: Chapter5-Answers.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-04
          Modified: 2019-06-04

          Version - 1.0.0 - (2019-06-04)
#>


##################################################################
#Region Exercise 5.3.1

#Question 1 – Using Remote PowerShell try interacting with the two clients provided to you in your lab.

#Solution 1
#Running as NON-Administrator of client01
Enter-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
$ENV:COMPUTERNAME
Exit-PSSession

#Soltuion 2 
#Running as NON-Administrator of client01
New-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Enter-PSSession
$ENV:COMPUTERNAME
Exit-PSSession
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Remove-PSSession

#Question 2 - Remote PowerShell try get information about the two machines and their running services.

#Solution 1 - Note will not work unless running as an admin of the remote machine

Get-Service -ComputerName CLIENT01

#Solution 2

Enter-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
Get-Service
Exit-PSSession

#Solution 3
New-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Enter-PSSession
Get-Service
Exit-PSSession
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Remove-PSSession

#Question 3 - Try getting all of the patches installed on both machines

#Soltion 1 -  Note will not work unless running as an admin of the remote machine
Get-HotFix -ComputerName CLIENT01

#Solution 2

Enter-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
Get-HotFix
Exit-PSSession

#Solution 3
New-PSSession -ComputerName CLient01 -Credential $(Get-Credential)
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Enter-PSSession
Get-HotFix
Exit-PSSession
Get-PSSession -ComputerName CLIENT01 -Credential $(Get-Credential) | Remove-PSSession

#Solution 4
$MachineList = @('CLIENT01','CLIENT02')
$Credential = Get-Credential
foreach($machine in $MachineList){
     Enter-PSSession -ComputerName $machine -Credential $Credential
     $Hotfixlist = Get-HotFix
     Write-Output -InputObject "The installed patches on $($Machine) are"
     Write-Output -InputObject $Hotfixlist
     Exit-PSSession
}
$Credential = $null


#endregion Exercise 5.3.1
##################################################################

##################################################################
#Region Exercise 5.3.2

#Question 1 - Write a script that gets the most recently installed update from Client01 and Client02 using a for each loop and using the invoke command.
#Solution 1
$MachineList = @('CLIENT01','CLIENT02')
$Credential = Get-Credential
foreach($Machine in $MachineList){
     $Updates = Invoke-Command -ComputerName $Machine -Credential $Credential -ScriptBlock {Get-HotFix | Where-Object {$_.InstalledOn -ne $null} | Sort-Object -Descending InstalledOn}
     Write-Output -InputObject ""
     Write-Output -InputObject "The most recent update for $($Machine) is"
     Write-Output -InputObject $Updates[0]
}
$Credential = $null

#Question 2 - Write script that does the above but as a job for each computer. 

#solution 1
#Note - The question doesn't ask you to get the status of the jobs - YET - that's question 3 just write it as a job the getting the status comes next. 
$Credential = Get-Credential
foreach($Machine in $MachineList){
     $Updates = Invoke-Command -ComputerName $Machine -Credential $Credential -ScriptBlock {Get-HotFix | Where-Object {$_.InstalledOn -ne $null} | Sort-Object -Descending InstalledOn} -AsJob
     Write-Output -InputObject ""
     Write-Output -InputObject "The most recent update for $($Machine) is"
     Write-Output -InputObject $Updates[0]
}
$Credential = $null

#Question 3 - Using a DO UNTIL or DO WHILE loop keep checking the status of the jobs until they are done and then return the result only when both jobs are done in a hash array. 
#Solution 1 - This is a working solution what are some other things you could add to make this even better? - Using a DO- until
$Credential = Get-Credential
foreach($Machine in $MachineList){
     $Updates = Invoke-Command -ComputerName $Machine -Credential $Credential -ScriptBlock {Get-HotFix | Where-Object {$_.InstalledOn -ne $null} | Sort-Object -Descending InstalledOn} -AsJob -JobName "$($Machine)-Job"
}
Do{
     Write-Verbose -Message "Starting to wait for 5 seconds to try to allow jobs to complete" -Verbose
     Start-Sleep -Seconds 5
     Write-Verbose -Message "Completed sleep now looking for jobs" -Verbose
     $CompltedJobs = Get-Job | Where-Object {($MachineList -contains $_.Location) -and ($_.State -eq "Completed")}
     if($CompltedJobs){
          Write-Verbose -Message "We found some completed jobs" -Verbose
          foreach($Job in $CompltedJobs){
               $updateList = Receive-Job -Id $Job.Id
               Write-Output -InputObject ""
               Write-Output -InputObject "The most recent update for $($Job.Location) is"
               Write-Output -InputObject $updateList[0]
               Remove-Job -Id $Job.Id
          }
          Write-Verbose -Message "Now emptying the job checker"
          $CompltedJobs = $null 
     }
     elseif (-not($CompltedJobs)) {
          Write-Verbose -Message "No completed jobs were found this time." -verbose
     }
}
until(-not(Get-Job | Where-Object {($MachineList -contains $_.Location)}))
$Credential = $null

#Solution 2 - Using a While Loop

$Credential = Get-Credential
foreach($Machine in $MachineList){
     $Updates = Invoke-Command -ComputerName $Machine -Credential $Credential -ScriptBlock {Get-HotFix | Where-Object {$_.InstalledOn -ne $null} | Sort-Object -Descending InstalledOn} -AsJob -JobName "$($Machine)-Job"
}
while ((Get-Job | Where-Object {($MachineList -contains $_.Location)})) {
     Write-Verbose -Message "Starting to wait for 5 seconds to try to allow jobs to complete" -Verbose
     Start-Sleep -Seconds 5
     Write-Verbose -Message "Completed sleep now looking for jobs" -Verbose
     $CompltedJobs = Get-Job | Where-Object {($MachineList -contains $_.Location) -and ($_.State -eq "Completed")}
     if($CompltedJobs){
          Write-Verbose -Message "We found some completed jobs" -Verbose
          foreach($Job in $CompltedJobs){
               $updateList = Receive-Job -Id $Job.Id
               Write-Output -InputObject ""
               Write-Output -InputObject "The most recent update for $($Job.Location) is"
               Write-Output -InputObject $updateList[0]
               Remove-Job -Id $Job.Id
          }
          Write-Verbose -Message "Now emptying the job checker"
          $CompltedJobs = $null 
     }
     elseif (-not($CompltedJobs)) {
          Write-Verbose -Message "No completed jobs were found this time." -verbose
     }
}
$Credential = $null

#endregion Exercise 5.3.2
##################################################################




##################################################################
#Region Exercise 
#endregion Exercise 
##################################################################