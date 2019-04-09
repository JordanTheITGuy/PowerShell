$MWName = "MAINT - SERVER - "
[int32]$DayCounter = 0
$list = New-Object System.Collections.ArrayList($null)
$Schedule = New-CMSchedule -Start (Get-Date) -DayOfWeek Saturday -RecurCount 1
Do
{
    $DayCounter++ | Out-Null
    $NewString = $MWName + "PROD" + $DayCounter
    $List.add($NewString)
}
while($DayCounter.ToString() -ne '30')
$FullList = New-Object System.Collections.ArrayList($null)
foreach($Object in $list)
    {
        [int32]$WindowCounter = 0
        
        do 
            {
                $WindowCounter++
                $NewCollection = $Object + "W" + $WindowCounter.ToString()
                $FullList.Add($NewCollection)
            }
        while ($WindowCounter.ToString() -ne "6")
    }
ForEach($CollectionName in $FullList)
    {
        New-CMCollection -collectionType Device -Name $CollectionName -LimitingCollectionId 'PR100079' -RefreshSchedule $Schedule -RefreshType Periodic | Out-Null
        $Object = Get-CMCollection -Name $CollectionName
        Move-CMObject -FolderPath 'PR1:\DeviceCollection\Patching Collections' -InputObject $Object
    }
