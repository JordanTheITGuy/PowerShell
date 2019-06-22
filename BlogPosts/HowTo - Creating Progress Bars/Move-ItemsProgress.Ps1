$Contents = Get-ChildItem -Path "C:\Users\jbenz001\Desktop\Folder1"
$Destination = "C:\Users\jbenz001\Desktop\Folder2"
foreach($Item in $Contents){
    Move-Item -path $Item.FullName -Destination $Destination
    [int]$currentItem = [array]::indexof($Contents,$Item)
    Write-Progress -Activity "Moving files" -Status "Currently Moving - $($Item.Name) - File $($currentItem) of $($Contents.Count - 1) $([math]::round((($currentItem + 1)/$Contents.Count),2) * 100)% " -PercentComplete $([float](($currentItem + 1)/$Contents.Count) * 100)
    Start-Sleep -Seconds 1
}

