#Retrieve the current settings.JSON content and convert it from JSON into a PowerShell object. 
$Obj = Get-Content -Path "$ENV:AppData\Code\User\settings.json" | ConvertFrom-Json
#Add the member item and the property value that should be attached to it in this case Powershell
$Obj | Add-Member -Name "files.defaultLanguage" -Value "powershell" -MemberType NoteProperty
#Convert the content back to JSON
$Content = ConvertTo-Json $Obj
#Set the JSON and apply it over the top of the settings.JSON files
Set-Content -Path "$ENV:AppData\Code\User\settings.json" -Value $Content