function Out-CompletionInfo
{
[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Title for the message box")]
    [string]$Title,
    [Parameter(HelpMessage = "Horizontal Widge of the window", Mandatory = $True)]
    [Int32]$XSize,
    [Parameter(HelpMessage = "Vertical size of the window", Mandatory = $True)]
    [Int32]$YSize
)
begin
{
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
}

process
{
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Icon = "C:\Users\jbenz001\OneDrive\GitHub\ProblemResolution\PowerShell\Functions\logo_Sw3_12.ico"
    $objForm.BackColor = "White"
    $objForm.Text = "$($Title)"
    $objForm.Size = New-Object System.Drawing.Size($XSize,$YSize) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({
        if ($_.KeyCode -eq "Enter" -or $_.KeyCode -eq "Escape"){
            $objForm.Close()
        }
    })

    #OK Button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(10,$($YSize-80))
    $OKButton.Size = New-Object System.Drawing.Size(75,25)
    $OKButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
    $OKButton.Text = "OK"
    $OKButton.Add_Click({
        $objForm.DialogResult = "OK"
        $objForm.Close()
    })
    $objForm.Controls.Add($OKButton)

    #Open Logs Button Logic
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size($($XSize - 100),$($YSize - 80))
    $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Logs"
    $CancelButton.Add_Click({
        $startinfo = new-object System.Diagnostics.ProcessStartInfo 
        $startinfo.FileName = "explorer.exe"
        $startinfo.WorkingDirectory = "C:\Users\jbenz001\Downloads"
        [System.Diagnostics.Process]::Start($startinfo)
        $objForm.Close()
    })
    $objForm.Controls.Add($CancelButton)

    #Intro Information
    $DisplayText = New-Object System.Windows.Forms.Label
    $Font = New-Object System.Drawing.Font("Times New Roman",12,[System.Drawing.FontStyle]::Regular)
    $DisplayText.Font = $Font
    $DisplayText.Location = New-Object System.Drawing.Size(15,15)
    $DisplayText.Size = New-Object System.Drawing.Size($($XSize - 30),($YSize-90))
    $DisplayText.Text = "The PowerShell Hydration tool kit has now complated. We have installed the following features:

    [$($Win10ADKStatus)] Windows 10 ADK Version - $($Win10ADKVersion)
    [$($Win10ADKPEStatus)] Windows 10 ADK PE Version - $($Win10ADKPEVersion) 
    [$($MDTStatus)] Microsoft Deployment ToolKit Version - $($MDTVersion)
    [$($ShareStatus)] Created an Deployment share - $($ShareName)
    [$($IISStatus)] Created an IIS Website - $($WebSiteName)
    [$($IISconfigureStatus)] Configured IIS as HTTP/S - $($WebsiteName)

You may read more about this information in the logs stored in the Hydration folder and the install folder. Thank you for running the PowerShell Deployment Toolkit"
    $objForm.Controls.Add($DisplayText)
    $objForm.Topmost = $True
    $objForm.Add_Shown({$objForm.Activate()})
    [void]$objForm.ShowDialog()
}
}

Out-MessageData -XSize 500 -YSize 350 -Title "PowerShell Deployment ToolKit Hydration"

