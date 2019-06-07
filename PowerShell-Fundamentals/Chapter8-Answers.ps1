<#
.SYNOPSIS
    These scripts are the answer key to the PowerShell fundamentals book

.DESCRIPTION
    These scripts are the answer key to the PowerShell Fundamentals book and course run by TrueSec INC
    The below functions are meant as examples and should not be used in real world environments without 
    fully understanding the intention of the scripts. 

.LINK
    

.NOTES
          FileName: Chapter8-Answers.ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-06-07
          Modified: 2019-06-07

          Version - 0.0.0 - (2019-06-07)
#>

##################################################################
#Region Exercise 8.4.1

#Question 1 – Using what you have learned, create a PowerShell object of some type that has all of the information needed to create a user account, AND an admin account for everyone in the classroom – or a bunch of random friends. Using this object create and store the users in the CORRECT OU based on a naming standard. 
#Because of the NUMBER of ways that this can be solved - there is no TRUE answer key written for this question set instead some Pseudo guide is written for you to have 
#Some workign structure is provided. 

#PseudoCode 
<#
    Goal - Create X number of users with
            - UserID
            - Name
            - SurName
            - Password
            - Expiration Date

    Start - We have no Data, no CSV to import nothing. 
        Options
            - Create a static CSV with most of the information in it and then generate the rest as needed on the fly. 
            - Create a function that when passed a users first name and last name it generates the rest of the needed information
            - Create a Hash Table/PSobject set with all relavent information hardcoded and then generate a bunch of users. 
    
    Methods
            - CSV 
                    Create Function that imports CSV information
                        Should test the CSV actually exists
                    Create function that parses CSV information 
                    Create function that generates passwords and other NEEDED information and stores as dedicated "user object"
                    Create function that Creates the AD user in the correct location.
                    Create Logging function that TRACKS the creation process. 
#>



#Question 2 – Using What you have learned, retrieve the users objects for all of the users you just created and using a naming standard of your choice use the information in their AD object to build an e-mail address for them on the fly. 

<#
PSEUDO Code
    Get-AD Users 
    Using information Create E-mail address
    Set -EMAIL address 
    Confirm valid and that it is set. 
#>

#Question 3 – Using What you have learned, retrieve users that have never logged in and validate they are not the "Administrator" or "student" or BUILT-IN accounts, Disable those accounts. 

<#
    Goal - Disable users that have never logged in and are not named "Administrator" or "Student" or other BUILT-IN accounts
        Start - We have no idea what users have or have not logged in 
            Options:
                Retrieve all user objects from everywhere and check last login.
                Retrieve ALL users objects from managed User OUS - check last login disable

        Method 
            - Import AD Module
            - Retrieve AD Users - that Match in-scope users
            - Evaluate the retrieved AD users and the last logon property
            - Disable users that meet the criteria and make a note about it. 
            - Logging if applicable
 #>


#endregion Exercise 8.4.1
##################################################################

##################################################################
#Region Exercise 8.4.2

#Question 1 – Using what you have learned find all of the roles that are installed on DC01.

#Solution 1

Get-WindowsFeature -ComputerName "DC01" -Credential $(Get-Credential) -Verbose

#Solution 2

Invoke-Command -ComputerName "DC01" -Credential $(Get-Credential) -ScriptBlock {Get-WindowsFeature}

#Solution 3
Enter-PSSession -ComputerName "DC01" -Credential $(Get-credential)
Get-WindowsFeature
Exit-PSSession

#Question 2 – Using what you have learned find what roles are installed on SRV01.

#Solution 1

Get-WindowsFeature -ComputerName "SRV01" -Credential $(Get-Credential) -Verbose

#Solution 2

Invoke-Command -ComputerName "SRV01" -Credential $(Get-Credential) -ScriptBlock {Get-WindowsFeature}

#Solution 3
Enter-PSSession -ComputerName "SRV01" -Credential $(Get-credential)
Get-WindowsFeature
Exit-PSSession

#Question 3 – Using what you have learned install IIS on SRV01 remotely using PowerShell and see find out if you need to reboot. 

#Solution 1
$IISResults = Install-WindowsFeature -Name Web-Server -ComputerName "SRV01" -Verbose:$false
if ($IISREsults.ExitCode.Value__ -eq "3010"){
    Write-Verbose -Message "You need to reboot" -Verbose
}
else {
    Write-Verbose -Message "Installed with exit code $($IISREsults.ExitCode.Value__)"
}

#Question 4 – Using what you have learned install IIS and the following features. 
$Featurelist = @("Web-Custom-Logging","Web-Log-Libraries","Web-Request-Monitor","Web-Http-Tracing","Web-Security","Web-Filtering","Web-Basic-Auth","Web-Digest-Auth","Web-Url-Auth","Web-Windows-Auth","Web-Mgmt-Console","Web-Metabase","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-DAV-Publishing")
$FeatureResults = Install-WindowsFeature -Name $Featurelist -ComputerName $ComputerName

#You could also use a ForEach loop - If you enable snapshots and test this you will find that one way is significantly faster than the other. 

#endregion Exercise 8.4.2
##################################################################

##################################################################
#Region Exercise 8.4.3

#Question 1 – Using Pseudo Code – Write out a quick way to determine if the Configuration Manager console is installed. 

<#
    Get Contents of $ENV:
    If Contents of $ENV contain the SMS_ environment variables for the console install location
    Then return the console is installed and the module CAN be loaded.
#>

#Question 2 – Using Pseudo Code – Write out how you would import the ConfigMgr PowerShell cmdlets if they were not present and find the ConfigMgr provider drive. 

<#
    Get-Contents of $ENV
    If contents of $ENV contain the SMS_Environment variables for the console install location
    Then return the console is installed and the module CAN be loaded. 
    Test access to the location where the module file is loaded using the $ENV variable
    If we can reach it then import the module. 
    If the module loads succesfully Get the PSDrives that are now mounted to the system
    Find the drive that has the ConfigMGR provider attached to it. 
    Store the CURRENT location. 
    Set-Location to desired location of the ConfigMgr Drive. 
#>

#endregion Exercise 8.4.3
##################################################################