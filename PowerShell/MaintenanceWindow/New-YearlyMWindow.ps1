<#
.SYNOPSIS
    This script creates Maintenance windows for an entire year

.DESCRIPTION
    Use this to remove all maintenance windows from collections that match certain criteria
        

.EXAMPLE
	The script is static and does not have any functions to use for an example.

.NOTES
    FileName:    New-YearlyMWindow.PS1
    Author:      Jordan Benzing
    Contact:     @JordanTheItGuy
    Created:     2018-12-13
    Updated:     2018-12-13
#>

################################# Variables ################################################

$SiteCode = "PR1"
$CollectionName = "SUM - Servers - PROD*"
$MWName = "NAT Patching"
$MWDescription = "Patching Window"
$MWDuration = 4
$StartMinute = 0
$MinuteDuration = 0
$Year = 2019
############################################################################################
#region Get-PatchWindow -Window $Arg 
Function Get-PatchWindowTime
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(
            Mandatory = $True
        )]
        $Window
    )

    Switch ($Window)  # Determine Window
    {
        # Window 1 00:00 to 04:00
        'W1' {
            $Description = 'Window 1 00:00 to 04:00'
            $StartHour = '0'
        }

        # Window 2 04:00 to 08:00
        'W2' {
            $StartHour = '4'
            $Description = 'Window 2 04:00 to 08:00'
        }

        # Window 3 08:00 to 12:00
        'W3' {
            $StartHour = '8'
            $Description = 'Window 3 08:00 to 12:00'
        }
               
        # Window 4 12:00 to 16:00
        'W4' {
            $StartHour = '12'
            $Description = 'Window 4 12:00 to 16:00'
        }

        # Window 5 16:00 to 20:00
        'W5' {
            $StartHour = '16'
            $Description = 'Window 5 16:00 to 20:00'
        }

        # Window 6 20:00 to 00:00
        'W6' {
            $StartHour = '20'
            $Description = 'Window 6 20:00 to 00:00'
        }

        # If group name match fails, log name, do not create schedule
        Default {
            write-verbose -message "Start Time failed." -Verbose
        }

    } # End switch

    Return $StartHour,$Description
}
#endregion
#region Get-PatchStartDay -DayType $Arg 
Function Get-PatchWindowType
{
    [cmdletbinding()]
    Param
    (
        [Parameter(
            Mandatory = $True
        )]
        $DayType
    )

        #Add days for Production day, Test days do not need added.

    
    [int]$WinType = 0

    $DaysAdded = $WinType + $DaysAfter

    Return $DaysAdded
}
#endregion

$curloc = get-location | select -ExpandProperty Path

# set sitecode format and location for gathering collection info
If ($SiteCode -notlike "*:")
{
    Set-Location $($SiteCode + ":")
}else
{
    Set-Location $SiteCode
}

# Gather specific collections for processing with the MW script
$MWCollections = Get-CMDeviceCollection -Name $CollectionName | select name,collectionid

#Set back to current location - Could be switched to use $MyInvocation.MyCommand.Path instead

Set-Location $curloc

# loops breaks down the collection name to determine day and window
Foreach ($Collection in $MWCollections)
{
    Write-Verbose -Message "Processing $($Collection.name)..." -Verbose
    If ($($Collection.name.split(" - ")[6]).length -eq 8)
    {
        $Day = $Collection.name.split(" - ")[6].substring(4,2)
        $Window = $($Collection.Name.split(" - "))[6].substring(7)
    }else
    {
        $Day = $Collection.name.split(" - ")[6].substring(5,2)
        $Window = $($Collection.Name.split(" - "))[6].substring(7)
    }

    # Function call to determine patch window only
    $WindowInfo = Get-PatchWindowTime -Window $Window

    $StartHour = $WindowInfo[0]
    $MWDescription = $Day + " " + $WindowInfo[1]

    # Function call to determine patch day only
    $TotalDaysAdded = Get-PatchWindowType -DayType $Collection.name.split(" - ")[6].substring(0,4)
    $TotalDaysAdded = $TotalDaysAdded + 6

    Write-Verbose -Message "$($Collection.Name) `
         Start Hour : $StartHour `
         End Hour   : $([int]$StartHour + [int]$MWDuration)
         Days to add after Patch Tuesday: $TotalDaysAdded" -Verbose

    write-host
    Write-Verbose -Message "Creating maintenance windows for collection $($collection.name.ToUpper())" -Verbose
    write-host
    #write-host ".\createmw.ps1 -sitecode $Sitecode -MaintenanceWindowName `"$MWNameDetail`" -CollectionID $($Collection.collectionid) -HourDuration $MWDuration -MinuteDuration $MinuteDuration -swtype Updates -PatchTuesday -AddDays $TotalDaysAdded -StartYear $Year -StartMinute $StartMinute -AddMaintenanceWindowNameMonth -MaintenanceWindowDescription `"$MWDescription`""
    Invoke-Expression ".\createmw.ps1 -sitecode $Sitecode -MaintenanceWindowName `"$MWName`" -CollectionID $($Collection.collectionid) -HourDuration $MWDuration -MinuteDuration $MinuteDuration -swtype Updates -PatchTuesday -AddDays $TotalDaysAdded -StartYear $Year -StartHour 0 -StartMinute $StartMinute -AddMaintenanceWindowNameMonth -MaintenanceWindowDescription `"$MWDescription`""
    
}



