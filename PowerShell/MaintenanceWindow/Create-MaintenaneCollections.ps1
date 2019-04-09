<#
.SYNOPSIS
    This scripts creates maintenance window collections for servers based on provided criteria. 

.DESCRIPTION
    Use this script to create and move maintenace window collections to a desired location in your configuration manager environment. 
        

.EXAMPLE
    This script uses some parameters here is an example of usage:
    PR1:\> C:\scripts\Create-MaintenanceCollections.Ps1 -LimitingCollectionID "SMS00001" -NumberofDays 5 -FolderPath "PR1:\DeviceCollections\SUM - PatchingCollections\Maintenance Collections"

.NOTES
    FileName:    Create-MaintenanceCollections.PS1
    Author:      Jordan Benzing
    Contact:     @JordanTheItGuy
    Created:     2019-04-09
    Updated:     2019-04-09

    Version 1.0.1 - It works and creates stuff with no parameters and is cardcoded
    Version 1.0.2 - Added the ability to utilize Parameters
    Version 1.0.3 - Added verbosity to show each step as it goes along and some error checking. 

#>


param(
    [parameter(Mandatory = $true)]
    [string]$LimitingCollectionID,
    [parameter(Mandatory = $true)]
    [int]$NumberofDays,
    [Parameter(Mandatory = $true)]
    [string]$FolderPath
    )
#Ensure the Configuration Manager Module is loaded if it's not loaded see blog post on how to load it at www.scconfigmgr.com
Write-Verbose -Message "Confirming that the configuration manager module is loaded" -Verbose
if(!(Get-Module -Name ConfigurationManager)){
    Write-Error "YOU MUST HAVE THE CONFIGMGR MODULE LOADED"
    break
}
#Ensure the current location is the configuration manager provider PSdrive - if its not then break see how to connect to this location at www.scconfigmgr.com
Write-Verbose -Message "The configuration manager module IS LOADED continue" -Verbose
if(((Get-location).Path.Substring(0,4)) -ne "$(((Get-WmiObject -namespace "root\sms" -class "__Namespace").Name).substring(8-3)):"){
    Write-Error "YOU MUST BE IN THE CONFIGMGR DRIVE LOCATION"
    break
}
#Ensure the folder path you would like to move the collections to exists
Write-Verbose -Message "Now testing if the location to move the collections to exists and is written out properly." -Verbose
if(!(Test-Path -Path $FolderPath)){
    Write-Error -Message "The Path does not exist please re-run the script with a valad path"
    break
}
Write-Verbose "The location to move the collections to EXISTS and IS written out properly." -Verbose
#Set the naming standard for the collection name you MAY change this it's highly reccomended that you do NOT.
$MWName = "MAINT - SERVER - D"
Write-Verbose "The naming standard for your maintenance collections will be $($MWNAME) with the day after patch tuesday and window indication afterwords"
#Set the date counter to 0
$DayCounter = 0
#Create a list to store the collection names in. 
$list = New-Object System.Collections.ArrayList($null)
#Create a CMSchedule object - This sets the refresh on the collections you may change the below line otherwise collections will refresh weekly on saturday.
$Schedule = New-CMSchedule -Start (Get-Date) -DayOfWeek Saturday -RecurCount 1
Do
{
    #Add one to the day counter
    $DayCounter++
    #Create the new string - Collection name plus the count of days after patch tuesday.
    $NewString = $MWName + $DayCounter
    #Store the string into the list
    $List.add($NewString) | Out-Null
}
#Do this until the number of days you would like to have MW's for is reached.
while($DayCounter -ne $NumberofDays)
Write-Verbose "Created Day Names" -Verbose
#Create the Full list object - this will now add in the MW information (6 created per day each one is 4 hours long allowing you to patch anytime of the day)
$FullList = New-Object System.Collections.ArrayList($null)
#For each DAY/COLLECTION in the previous list CREATE 6 maintenance window collection names. 
foreach($Object in $list)
    {
        #Set the window counter back back to 0
        [int32]$WindowCounter = 0
        do 
            {
                #Add one to the window counter
                $WindowCounter++ 
                #Create the new collection name and add the nomenclature of W3 to it. 
                $NewCollection = $Object + "W" + $($WindowCounter.ToString())
                #Compile and store the finalized list name. 
                $FullList.Add($NewCollection) | Out-Null
            }
        #Do this until you reach 6 of them - you can of course change that if you really wanted to... but why? 
        while ($($WindowCounter.ToString()) -ne "6")
    }
#For each collection name in the FULL list of (MAINT - SERVER - D1W1 (example)) - create a collection limited to the specified limit and refresh weekly on Saturday.
Write-Warning -Message "The Action you are about to perfom will create $($FullList.Count) collections do you want to continue?" -WarningAction Inquire
Write-Verbose -Message "Created all MW Collection Names now creating the MW Collections" -Verbose
ForEach($CollectionName in $FullList)
    {
        try{
        #Create the collection
        Write-Verbose -Message "Now creating $($collectionName)" -Verbose
        $Object = New-CMCollection -collectionType Device -Name $CollectionName -LimitingCollectionId $LimitingCollectionID -RefreshSchedule $Schedule -RefreshType Periodic
        #Move the collection to its final destination.
        Move-CMObject -FolderPath $FolderPath -InputObject $Object
        Write-Verbose -Message "Successfully created and moved $($collectionName) to its destination" -Verbose
        }
        catch
        {
            Write-Error -Message $_.Exception.Message
        }
    }
Write-Output -InputObject $("Completed the script succesfully")