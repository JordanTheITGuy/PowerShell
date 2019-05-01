function Get-OSInfo
{
[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Please enter the path to the ISO here" )]
    [string]$ISOPath = "C:\Sources\",
    [Parameter(HelpMessage = "This parameter sets the OSVersion Number" )]
    [string]$OSVersion = "1709",
    [Parameter(HelpMessage = "This Parameter sets the OS Name" )]
    [string]$OSName = "Windows 10 1709",
    [Parameter(HelpMessage = "This Parameter sets the OS Folder Name in MDT Templates" )]
    [string]$OSFolderName = "W10X641709"
)
begin
{
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
}

process
{


    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "PSD Hydration ISO Import Info"
    $objForm.Size = New-Object System.Drawing.Size(350,300) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({
        if ($_.KeyCode -eq "Enter" -or $_.KeyCode -eq "Escape"){
            $objForm.Close()
        }
    })

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(10,225)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({$objForm.Close()})
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(250,225)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objForm.Close()})
    $objForm.Controls.Add($CancelButton)

    ###Field 1###
    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(315,20) 
    $objLabel.Text = "Please enter the OS information in the space below:"
    $objForm.Controls.Add($objLabel) 

    $objTextBox = New-Object System.Windows.Forms.TextBox 
    $objTextBox.Location = New-Object System.Drawing.Size(10,40) 
    $objTextBox.Size = New-Object System.Drawing.Size(315,20)
    #If you want to default this to something replace the text with your default
    $objTextBox.Text = $OSVersion
    $objForm.Controls.Add($objTextBox) 

    ###Field 2###
    $objLabel2 = New-Object System.Windows.Forms.Label
    $objLabel2.Location = New-Object System.Drawing.Size(10,70) 
    $objLabel2.Size = New-Object System.Drawing.Size(315,20) 
    $objLabel2.Text = "Please enter the OS NAME in the space below:"
    $objForm.Controls.Add($objLabel2)


    $objTextBox2 = New-Object System.Windows.Forms.TextBox 
    $objTextBox2.Location = New-Object System.Drawing.Size(10,90) 
    $objTextBox2.Size = New-Object System.Drawing.Size(315,20) 
    $objTextBox2.Text = $OSName
    $objForm.Controls.Add($objTextBox2)

    ###Field 3

    $objLabel3 = New-Object System.Windows.Forms.Label
    $objLabel3.Location = New-Object System.Drawing.Size(10,120) 
    $objLabel3.Size = New-Object System.Drawing.Size(315,20) 
    $objLabel3.Text = "Please enter the OS FOLDER in the space below:"
    $objForm.Controls.Add($objLabel3)

    $objTextBox3 = New-Object System.Windows.Forms.TextBox 
    $objTextBox3.Location = New-Object System.Drawing.Size(10,140) 
    $objTextBox3.Size = New-Object System.Drawing.Size(315,20) 
    $objTextBox3.Text = $OSFolderName
    $objForm.Controls.Add($objTextBox3) 

    ###Field 4
    $objLabel4 = New-Object System.Windows.Forms.Label
    $objLabel4.Location = New-Object System.Drawing.Size(10,170) 
    $objLabel4.Size = New-Object System.Drawing.Size(280,20) 
    $objLabel4.Text = "Please enter the ISO Location in the space below:"
    $objForm.Controls.Add($objLabel4)

    $objTextBox4 = New-Object System.Windows.Forms.TextBox 
    $objTextBox4.Location = New-Object System.Drawing.Size(10,190) 
    $objTextBox4.Size = New-Object System.Drawing.Size(315,20) 
    $objTextBox4.Text = $ISOPath
    $objForm.Controls.Add($objTextBox4)

    $objForm.Topmost = $True

    $objForm.Add_Shown({$objForm.Activate()})
    [void]$objForm.ShowDialog()

    $Hash = @{
        OSVersion = $objTextBox.Text
        OSname = $objTextBox2.Text
        OSFolderName = $objTextBox3.Text
        ISOLocation = $objTextBox4.Text
    }
    $Object = New-Object -TypeName psobject -Property $Hash
    return $Object
}
}
Get-OSInfo