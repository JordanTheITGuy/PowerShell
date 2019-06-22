Do{
    $Count++
    Write-Progress -Activity "Counting to 10" -Status "Running..." -PercentComplete $($count * 10) -CurrentOperation "Current number is $($count)"
    Start-Sleep -Seconds 1
}until($count -eq 10)
$count = $null