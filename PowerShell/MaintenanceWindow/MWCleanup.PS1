
Write-Verbose -Message "Getting Pilot Collection List" -Verbose
$Pilot = Get-CMCollection -Name 'SUM - Servers - PILOT*'
Write-verbose -Message "Succesfully retrieved pilot collections" -Verbose
Write-Verbose -Message "Now getting Production Collections" -Verbose
$Prod = Get-CMCollection -Name 'SUM - Servers - PROD*'
Write-Verbose -Message "Succesfully retrieved Production Collections" -Verbose
Write-Verbose -Message "Now cleaning Production Maintenance Windows pardon our dust..." -Verbose
foreach($Collection in $Prod)
    {
        Write-Verbose -Message "Retrieving maintenacne windows names" -Verbose
        $MaintenanceWindows = Get-CMMaintenanceWindow -CollectionName $Collection.Name
        foreach($MaintenanceWindow in $MaintenanceWindows)
            {
                Write-Verbose "Removing Maintenance window $($MaintenanceWindow.Name) from collection $($Collection.Name)" -Verbose
                Remove-CMMaintenanceWindow -CollectionName $Collection.Name -MaintenanceWindowName $MaintenanceWindow.Name -Force
                Write-Verbose "Successfully removed the MW for production collections" -Verbose
            }
    }
foreach($Collection in $Pilot)
    {
        Write-Verbose -Message "Retrieving maintenacne windows names" -Verbose
        $MaintenanceWindows = Get-CMMaintenanceWindow -CollectionName $Collection.Name
        foreach($MaintenanceWindow in $MaintenanceWindows)
            {
                Write-Verbose "Removing Maintenance window $($MaintenanceWindow.Name) from collection $($Collection.Name)" -Verbose
                Remove-CMMaintenanceWindow -CollectionName $Collection.Name -MaintenanceWindowName $MaintenanceWindow.Name -Force
                Write-Verbose "Successfully removed the MW for Pilot" -Verbose
            }
    }