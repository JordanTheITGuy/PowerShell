<#
.SYNOPSIS
    This script allows a user to add a set of active directory groups to a collection. The current design is around
    Machine based collections and Active Directory Groups. 


.DESCRIPTION
    Currently this script requires the Configuration Manager PowerShell Module to be installed. 

.LINK
    https://github.com/JordanTheITGuy/PowerShell/tree/master/BlogPosts/HowTo%20-%20Add%20an%20AD%20Group%20Query%20Rule%20to%20a%20collection%20with%20PowerShell

.NOTES
          FileName: Add-ADGroupRuleGui.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-10-10
          Modified: 2019-10-11

          Version - 0.0.0 - (2019-10-10)
          Version - 0.0.1 - (2019-10-10)
                  - Original code base written. It supports typing something in and adding a group to a collection using a 
                    pre-written rule as a here string. GUI using WinForms
          Version - 0.0.2 - (2019-10-11)
                  - Version 0.0.2 written Now supports searching the configMgr server for those groups
                  - Supports Search for collections
                  - supports imporing a CSV and running through a list of items. 
          Version - 0.0.3 - (2019-10-13)
                  - Added in DPI Scaling
                  - Added in search function if you hit enter when you are in a field
                  - Addedin starting notes. 


          #TODO: Add No GUI Option
          #COMPLETE: remove redundant checks for ConfigMgr code as currently we are checking every time we try to access it
          #TODO: Add a text box that shows the assumed SCCM Server.
          #ENHANCE: Fix Variable Names to be better - I'll do this at some point....


        
.EXAMPLE

#>


[cmdletbinding(DefaultParameterSetName = "None")]
param(
    [Parameter(HelpMessage = "This switch enables the script to be run independently and does NOT launch the forms GUI",Mandatory = $false, ParameterSetName = "NOGUI")]
    [switch]$NOGUI,
    [Parameter(HelpMessage = "This parameter is for the collection ID of the device you would like to add.",Mandatory = $true, ParameterSetName = "NOGUI")]
    [string]$CollectionID,
    [Parameter(HelpMessage = "This parameter is for the AD Group name you would like to bind to the collection.",Mandatory = $true, ParameterSetName = "NOGUI")]
    [string]$ADGroupNAme
)
begin{

#region helperfunctions
function Get-CMModule {
    [CmdletBinding()]
    param()
    Try
    {
        Write-Debug -message "Attempting to import SCCM Module"
        #Retrieves the fcnction from ConfigMgr installation path. 
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        Write-Debug -Message "Succesfully imported the SCCM Module"
    }
    Catch
    {
        Throw "Failure to import SCCM Cmdlets."
    } 
}

function Test-ConfigMgrAvailable {
    [CMdletbinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [bool]$Remediate
    )
        try
        {
            if((Test-Module -ModuleName ConfigurationManager -Remediate:$true) -eq $false)
            #Checks to see if the Configuration Manager module is loaded or not and then since the remediate flag is set automatically imports it.
            { 
                throw "You have not loaded the configuration manager module please load the appropriate module and try again."
                #Throws this error if even after the remediation or if the remediation fails. 
            }
            write-debug -Message "ConfigurationManager Module is loaded"
            write-debug -Message "Checking if current drive is a CMDrive"
            if((Get-location -Verbose:$false).Path -ne (Get-location -PSProvider 'CmSite' -Verbose:$false).Path)
            #Checks if the current location is the - PS provider for the CMSite server. 
            {
                write-debug -Message "The location is NOT currently the CMDrive"
                if($Remediate)
                #If the remediation field is set then it attempts to set the current location of the path to the CMSite server path. 
                    {
                        write-debug -Message "Remediation was requested now attempting to set location to the the CM PSDrive"
                        Set-Location -Path (((Get-PSDrive -PSProvider CMSite -Verbose:$false).Name) + ":") -Verbose:$false
                        write-debug -Message "Succesfully connected to the CMDrive"
                        #Sets the location properly to the PSDrive.
                    }

                else
                {
                    throw "You are not currently connected to a CMSite Provider Please Connect and try again"
                }
            }
            write-debug -Message "Succesfully validated connection to a CMProvider"
             $true
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            write-error -Exception CMPatching -Message $errorMessage
             $false
        }
}

function Test-Module {
    [CMdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$ModuleName,
        [Parameter(Mandatory = $false)]
        [bool]$Remediate
    )
    If(Get-Module -Name $ModuleName)
    #Checks if the module is currently loaded and if it is then return true.
    {
        write-debug -Message "The module was already loaded return  TRUE"
         $true
    }
    If((Get-Module -Name $ModuleName) -ne $true)
    #Checks if the module is NOT loaded and if it's not loaded then check to see if remediation is requested. 
    {
        write-debug -Message "The Module was not already loaded evaluate if remediation flag was set"
        if($Remediate -eq $true)
        #If the remediation flag is selected then attempt to import the module. 
        {
            try 
            {
                    if($ModuleName -eq "ConfigurationManager")
                    #If the module requested is the Configuration Manager module use the below method to try to import the ConfigMGr Module.
                    {
                        write-debug -Message "Non-Standard module requested run pre-written function"
                        Get-CMModule
                        #Runs the command to get the COnfigMgr module if its needed. 
                        write-debug -Message "Succesfully loaded the module"
                        $true
                    }
                    else
                    {
                    write-debug -Message "Remediation flag WAS set now attempting to import module $($ModuleName)"
                    Import-Module -Name $ModuleName
                    #Import  the other module as needed - if they have no custom requirements.
                    write-debug -Message "Succesfully improted the module $ModuleName"
                     $true
                    }
            }
            catch 
            {
                Write-Error -Message "Failed to import the module $($ModuleName)"
                break
            }
        }
        else {
            #Else return the fact that it's not applicable and  false from the execution.
            {
                 $false
            }
        }
    }
}

Function Start-Log {
         [CmdletBinding()]
         param (
         [string]$FilePath
          )
         try
              {
                    if(!(Split-Path $FilePath -Parent | Test-Path))
                    {
                         New-Item (Split-Path $FilePath -Parent) -Type Directory | Out-Null
                    }
                    #Confirm the provided destination for logging exists if it doesn't then create it.
                    if (!(Test-Path $FilePath))
                         {
                             ## Create the log file destination if it doesn't exist.
                             New-Item $FilePath -Type File | Out-Null
                         }
                         ## Set the global variable to be used as the FilePath for all subsequent Write-log
                         ## calls in this session
                         $global:ScriptLogFilePath = $FilePath
              }
         catch
         {
               #In event of an error write an exception
             Write-Error $_.Exception.Message
         }
}
     
Function Write-Log {
          param (
         [Parameter(Mandatory = $true)]
         [string]$Message,
         [Parameter()]
         [ValidateSet(1, 2, 3)]
          [string]$LogLevel=1,
          [Parameter(Mandatory = $false)]
         [bool]$writetoscreen = $true   
        )
         $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
         $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
         $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
          $Line = $Line -f $LineFormat
          [system.GC]::Collect()
         Add-Content -Value $Line -Path $global:ScriptLogFilePath
          if($writetoscreen)
          {
             switch ($LogLevel)
             {
                 '1'{
                     Write-Verbose -Message $Message
                     }
                 '2'{
                     Write-Warning -Message $Message
                     }
                 '3'{
                     Write-Error -Message $Message
                     }
                 Default {
                 }
             }
         }
          if($writetolistbox -eq $true)
          {
             $result1.Items.Add("$Message")
         }
}
     
function set-DefaultLogPath {
          [CmdletBinding()]
          param
          (
               [parameter(Mandatory = $false)]
               [bool]$defaultLogLocation = $true,
               [parameter(Mandatory = $false)]
               [string]$LogLocation
          )
          if($defaultLogLocation)
          {
               $LogPath = Split-Path $script:MyInvocation.MyCommand.Path
               $LogFile = "$($($script:MyInvocation.MyCommand.Name).Substring(0,$($script:MyInvocation.MyCommand.Name).Length-4)).log"		
               Start-Log -FilePath $($LogPath + "\" + $LogFile)
          }
          else 
          {
               $LogPath = $LogLocation
               $LogFile = "$($($script:MyInvocation.MyCommand.Name).Substring(0,$($script:MyInvocation.MyCommand.Name).Length-4)).log"		
               Start-$InfoGatherFormLog -FilePath $($LogPath + "\" + $LogFile)
          }
}

#endregion helperfunctions
function Set-ADGroupChoice{
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "GroupList Array from finding multiple groups. ")]
        [array]$GroupList
    )
    $GroupPicker = New-Object System.Windows.Forms.Form
    $GroupPicker.Text = 'Select an AD Group'
    $GroupPicker.Icon = "$(split-path $script:MyInvocation.MyCommand.Path)\SCConfigMgrLogo-Square.ico"
    $GroupPicker.Size = New-Object System.Drawing.Size(300,200)
    $GroupPicker.StartPosition = 'CenterScreen'

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $GroupPicker.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $GroupPicker.CancelButton = $CancelButton
    $GroupPicker.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Please select a Group'
    $GroupPicker.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(260,20)
    $listBox.Height = 80

    foreach($Group in $GroupList){
    [void] $listBox.Items.Add($Group.UsergroupName)
    }
   $GroupPicker.Controls.Add($listBox)

   $GroupPicker.Topmost = $true

    $result =$GroupPicker.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $x = $listBox.SelectedItem
        $X = $GroupList | Where-Object {$_.UsergroupName -eq $x}      
         $X
    }
}

function Set-CollectionChoice{
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "Collection List Array from finding multiple groups. ")]
        [array]$CollectionList
    )
    $CollectionPicker = New-Object System.Windows.Forms.Form
    $CollectionPicker.Text = 'Select A CM Collection'
    $CollectionPicker.Icon = "$(split-path $script:MyInvocation.MyCommand.Path)\SCConfigMgrLogo-Square.ico"
    $CollectionPicker.Size = New-Object System.Drawing.Size(300,200)
    $CollectionPicker.StartPosition = 'CenterScreen'

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $CollectionPicker.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $CollectionPicker.CancelButton = $CancelButton
    $CollectionPicker.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Please select a Collection'
    $CollectionPicker.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(260,20)
    $listBox.Height = 80

    foreach($Collection in $CollectionList){
    [void] $listBox.Items.Add($Collection.Name)
    }
   $CollectionPicker.Controls.Add($listBox)

   $CollectionPicker.Topmost = $true

    $result =$CollectionPicker.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $x = $listBox.SelectedItem
        $X = $CollectionList | Where-Object {$_.Name -eq $x}      
         $X
    }
}

function Get-GuiFilePath
{
         [cmdletbinding(DefaultParameterSetName = 'None')]
         param(
              [Parameter(HelpMessage ="Use this switch to identify the file type" , Mandatory=$true)]
              [string]$FileType,
              [Parameter(HelpMessage ="Use this switch to enable a message box explaining the prompt before hand." , Mandatory=$false , ParameterSetName = "MSGBOX")]
              [switch]$EnableMsgBox,
              [Parameter(HelpMessage ="This is the MESSAGE you would like to display before prompting for user input" , ParameterSetName = "MSGBOX" , Mandatory=$true)]
              [string]$Message,
              [Parameter(HelpMessage ="This is the message TITLE you would like to display before prompting for user input" , ParameterSetName= "MSGBOX" , Mandatory=$true )]
              [string]$MessageTitle
         )
         Add-Type -AssemblyName System.Windows.Forms
         Add-Type -AssemblyName Microsoft.VisualBasic
         if($EnableMsgBox)
         {
          $msboxReturn = [Microsoft.VisualBasic.Interaction]::MsgBox("$($Message)", "OKCancel,SystemModal,DefaultButton1", "SCConfigMgr MSG")
         }
         if($msboxReturn -eq "Cancel")
         {
              
         }
         $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
              Filter = "$($FileType) FILE (*.$($FileType))|*.$($FileType)"}
        $FileBrowser.InitialDirectory = $PSScriptRoot
         $Result = $FileBrowser.ShowDialog()
         if($Result -eq "Cancel"){
              
         }
         
         
          $FileBrowser
}
function Get-Information{
    [cmdletbinding()]
    param(
    )
    begin{
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
    }
    process{
            $InfoGatherForm = New-Object System.Windows.Forms.Form 
            $InfoGatherForm.Text = "SCConfigMgr - Add AD Group Query Rule To Collection"
            $InfoGatherForm.Icon = "$(split-path $script:MyInvocation.MyCommand.Path)\SCConfigMgrLogo-Square.ico"
            $InfoGatherForm.BackColor = [System.Drawing.Color]::LightGray
            $InfoGatherForm.Size = New-Object System.Drawing.Size(480,300) 
            $InfoGatherForm.StartPosition = "CenterScreen"
            $InfoGatherForm.AutoScalemode = "Dpi"
            $InfoGatherForm.AutoSize = $true
            $InfoGatherForm.AutoSizeMode = "GrowOnly"
        
            $InfoGatherForm.KeyPreview = $True
            $InfoGatherForm.Add_KeyDown({
                if ($_.KeyCode -eq "Enter" -or $_.KeyCode -eq "Escape"){
                    $InfoGatherForm.Close()
                }
            })
        
            #OK Button
            $OKButton = New-Object System.Windows.Forms.Button
            $OKButton.Location = New-Object System.Drawing.Size(10,225)
            $OKButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $OKButton.Size = New-Object System.Drawing.Size(75,23)
            $OKButton.Text = "OK"
            $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $OKButton.Add_Click({
                $InfoGatherForm.Close()
            })
            $InfoGatherForm.Controls.Add($OKButton)
            
            #Cancel Button
            $CancelButton = New-Object System.Windows.Forms.Button
            $CancelButton.Location = New-Object System.Drawing.Size(375,225)
            $CancelButton.Size = New-Object System.Drawing.Size(75,23)
            $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $CancelButton.Text = "Cancel"
            $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $CancelButton = $CancelButton
            $CancelButton.Add_Click({
                $InfoGatherForm.Close()
             })
            $InfoGatherForm.Controls.Add($CancelButton)
                  
            ###ADGroup Information###
            $GroupLabel = New-Object System.Windows.Forms.Label
            $GroupLabel.Location = New-Object System.Drawing.Size(10,20) 
            $GroupLabel.Size = New-Object System.Drawing.Size(315,20) 
            $GroupLabel.Text = "Enter The Group Name"
            $GroupLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $InfoGatherForm.Controls.Add($GroupLabel) 
        
            $GroupTextBox= New-Object System.Windows.Forms.TextBox 
            $GroupTextBox.Location = New-Object System.Drawing.Size(10,40) 
            $GroupTextBox.Size = New-Object System.Drawing.Size(315,20)
            $GroupTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $GroupTextBox.Text = ""
            $GroupTextBox.Add_KeyDown({
                if ($_.KeyCode -eq "Enter"){
                    $SearchADButton.PerformClick()
                }
            })

            $InfoGatherForm.Controls.Add($GroupTextBox)
            
            ###AD Group Search###
            $SearchADButton = New-Object System.Windows.Forms.Button
            $SearchADButton.Location = New-Object System.Drawing.Size(375,40)
            $SearchADButton.Size = New-Object System.Drawing.Size(75,23)
            $SearchADButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $SearchADButton.Text = "Search"
            $SearchADButton.Add_Click({                
                    if($SiteCodeTextBox.Text -eq $(Get-PSDrive | Where-Object {$_.Provider -match "CMSite"}).Name){
                        $ADGroup = $GroupTextBox.Text
                        if($ADGroup.Length -gt '0'){
                            if($ADGroup.Substring($ADGroup.Length -1) -eq "*"){
                                $ADGroup = "$($ADGroup.Substring(0,$ADGroup.Length-1))%"
                            }
                            elseif (!($ADGroup.Substring($ADGroup.Length -1) -eq "%")){
                                $ADGroup = "$($ADGroup)%"
                            }
                        }
                        $ADGroup = Get-CimInstance -ComputerName "$($(Get-PSDrive | Where-Object {$_.Provider -match 'CMSite'}).Root)" -Namespace "Root\SMS\site_$($SiteCodeTextBox.Text)" -Query "select distinct name,UserGroupName from SMS_R_UserGroup where UserGroupName like '$($ADGroup)'"
                        if(($ADGroup | Measure-Object).Count -eq 1){
                            $GroupTextBox.Text = $ADGroup.UserGroupName
                            $GroupTextBox.Update()
                        }
                        elseif(($ADGroup | Measure-Object).Count -gt 1){
                            $GroupName =  Set-ADGroupChoice -GroupList $ADGroup
                            $GroupTextBox.Text = $GroupName.UsergroupName
                            $GroupTextBox.Update()
                        }
                        Else{
                            $GroupTextBox.Text = "GROUP NOT FOUND"
                        }
                    }
                    else{
                        $GroupTextBox.Text = "MUST supply site code search ConfigMGr for group"
                        $GroupTextBox.Update()
                    }
            })
            $InfoGatherForm.Controls.Add($SearchADButton)

            ###Collection ID Information###
            $CollectionLabel = New-Object System.Windows.Forms.Label
            $CollectionLabel.Location = New-Object System.Drawing.Size(10,70) 
            $CollectionLabel.Size = New-Object System.Drawing.Size(135,20) 
            $CollectionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionLabel.Text = "Enter Collection ID     OR"
            $InfoGatherForm.Controls.Add($CollectionLabel)
        
            $CollectionIDTextBOX = New-Object System.Windows.Forms.TextBox 
            $CollectionIDTextBOX.Location = New-Object System.Drawing.Size(10,90) 
            $CollectionIDTextBOX.Size = New-Object System.Drawing.Size(120,20) 
            $CollectionIDTextBOX.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionIDTextBOX.AutoSize = $True
            $CollectionIDTextBOX.Text = ""
            $CollectionIDTextBOX.Add_KeyDown({
                if ($_.KeyCode -eq "Enter"){
                    $SearchCollButton.PerformClick()
                }
            })
            $InfoGatherForm.Controls.Add($CollectionIDTextBOX)
        
            ###Collection Name Info###

            $ColNameLabel = New-Object System.Windows.Forms.Label
            $ColNameLabel.Location = New-Object System.Drawing.Size(145,70) 
            $ColNameLabel.Size = New-Object System.Drawing.Size(200,20) 
            $ColNameLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $ColNameLabel.Text = "Collection Name"
            $InfoGatherForm.Controls.Add($ColNameLabel)

            $ColNameTextBox = New-Object System.Windows.Forms.TextBox
            $ColNameTextBox.Location = New-Object System.Drawing.Size(150,90) 
            $ColNameTextBox.Size = New-Object System.Drawing.Size(175,20)
            $ColNameTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $ColNameTextBox.AutoSize = $True
            $ColNameTextBox.Text = ""
            $ColNameTextBox.Add_KeyDown({
                if ($_.KeyCode -eq "Enter"){
                    $SearchCollButton.PerformClick()
                }
            })
            $InfoGatherForm.Controls.Add($ColNameTextBox)

            ###Search Button###
            $SearchCollButton = New-Object System.Windows.Forms.Button
            $SearchCollButton.Location = New-Object System.Drawing.Size(375,90)
            $SearchCollButton.Size = New-Object System.Drawing.Size(75,23)
            $SearchCollButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $SearchCollButton.Text = "Search"
            $SearchCollButton.Add_Click({
                    $ColID = $CollectionIDTextBOX.Text
                    $ColName = $ColNameTextBox.Text
                    if($ColID){
                        try{
                            $CollInfo = Get-CMDeviceCollection -Id $ColID -ErrorAction Stop | select-object Name,collectionID
                            if($($CollInfo | Measure-Object).Count -eq 1){
                                $CollectionIDTextBOX.Text = $CollInfo.collectionID
                                $ColNameTextBox.Text = $CollInfo.Name
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()
                            }
                            elseif (($CollInfo | Measure-Object).Count -gt 1) {
                                $CollectionPicked = Set-CollectionChoice -CollectionList $CollInfo
                                $CollectionIDTextBOX.Text = $CollectionPicked.collectionID
                                $ColNameTextBox.Text = $CollectionPicked.Name
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()                                    
                            }
                            elseif (($CollInfo | Measure-Object).Count -eq 0) {
                                $CollectionIDTextBOX.Text = "NO RESULTS FOUND"
                                $ColNameTextBox.Text = "NO RESULTS FOUND"
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()                                
                            }
                        }
                        catch{
                        }
                    }
                    if($ColName){
                        try{
                            if($ColName.Substring($ColName.Length -1) -eq "%"){
                                $ColName = "$($ColName.Substring(0,$ColName.Length-1))*"
                            }
                            elseif (!($ColName.Substring($ColName.Length -1) -eq "*")) {
                                $ColName = "$($ColName)*"
                            }
                            $CollInfo = Get-CMDeviceCollection -Name $ColName -ErrorAction Stop | select-object Name,collectionID
                            if($($CollInfo | Measure-Object).Count -eq 1){
                                $CollectionIDTextBOX.Text = $CollInfo.collectionID
                                $ColNameTextBox.Text = $CollInfo.Name
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()
                            }
                            elseif (($CollInfo | Measure-Object).Count -gt 1) {
                                $CollectionPicked = Set-CollectionChoice -CollectionList $CollInfo
                                $CollectionIDTextBOX.Text = $CollectionPicked.collectionID
                                $ColNameTextBox.Text = $CollectionPicked.Name
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()                                
                            }
                            elseif (($CollInfo | Measure-Object).Count -eq 0) {
                                $CollectionIDTextBOX.Text = "NO RESULTS FOUND"
                                $ColNameTextBox.Text = "NO RESULTS FOUND"
                                $CollectionIDTextBOX.Update()
                                $ColNameTextBox.Update()                                
                            }
                        }
                        catch{
                            Write-Error -Message "Something has gone seriously wrong if you've managed this one" -ErrorAction Stop
                            Break
                        }
                        
                    }
                })
            $InfoGatherForm.Controls.Add($SearchCollButton)
                  
            ###Site Server ID ###
            $SiteCodeLabel = New-Object System.Windows.Forms.Label
            $SiteCodeLabel.Location = New-Object System.Drawing.Size(10,120) 
            $SiteCodeLabel.Size = New-Object System.Drawing.Size(100,20) 
            $SiteCodeLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $SiteCodeLabel.Text = "Site Server ID"
            $InfoGatherForm.Controls.Add($SiteCodeLabel)
        
             
           $SiteCodeTextBox = New-Object System.Windows.Forms.TextBox 
           $SiteCodeTextBox.Location = New-Object System.Drawing.Size(10,140) 
           $SiteCodeTextBox.Size = New-Object System.Drawing.Size(120,20) 
           $SiteCodeTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
           $SiteCodeTextBox.AutoSize = $True
           $CMSiteCode = $(Get-PSDrive | Where-Object {$_.Provider -match "CMSite"}).Name
           $SiteCodeTextBox.Text = "$CMSiteCode"
           $InfoGatherForm.Controls.Add($SiteCodeTextBox)

            ###CSV Info###

            $CSVLabel = New-Object System.Windows.Forms.Label
            $CSVLabel.Location = New-Object System.Drawing.Size(150,120) 
            $CSVLabel.Size = New-Object System.Drawing.Size(200,20) 
            $CSVLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CSVLabel.Text = "CSV Path"
            $InfoGatherForm.Controls.Add($CSVLabel)

            $CSVTextBox = New-Object System.Windows.Forms.TextBox
            $CSVTextBox.Location = New-Object System.Drawing.Size(150,140) 
            $CSVTextBox.Size = New-Object System.Drawing.Size(175,20)
            $CSVTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CSVTextBox.AutoSize = $True
            $CSVTextBox.Text = ""
            $InfoGatherForm.Controls.Add($CSVTextBox)

            ###Search CSV Button###
            $SearchCSVButton = New-Object System.Windows.Forms.Button
            $SearchCSVButton.Location = New-Object System.Drawing.Size(375,140)
            $SearchCSVButton.Size = New-Object System.Drawing.Size(75,23)
            $SearchCSVButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $SearchCSVButton.Text = "Browse"
            $SearchCSVButton.Add_Click({
                $Info = Get-GuiFilePath -Message "Windows CSV" -MessageTitle "Windows CSV" -FileType "CSV"
                If($Info.FileName -ne ""){
                $CSVTextBox.Text = $Info.FileName
                $CSVTextBox.Refresh()
                $CSV = Import-Csv -Path $Info.FileName
                $CollectionID = Get-CMDeviceCollection -Name $CSV[0].CollectionName | Select-object -ExpandProperty collectionID
                $GroupTextBox.Text = $CSV[0].GroupName
                $ColNameTextBox.Text = $CSV[0].CollectionName
                $CollectionIDTextBOX.Text = $CollectionID
                $GroupTextBox.Refresh()
                $ColNameTextBox.Refresh()
                $CollectionIDTextBOX.Refresh()
                }
            })
            $InfoGatherForm.Controls.Add($SearchCSVButton)

            ###Display Form###

            $InfoGatherForm.Topmost = $True
            $InfoGatherForm.Add_Shown({$GroupTextBox.Select()})
            $Result = $InfoGatherForm.ShowDialog()
            if($Result -eq [System.Windows.Forms.DialogResult]::OK){
            $Hash = [ordered]@{
                GroupName = $GroupTextBox.Text
                collectionID = $CollectionIDTextBOX.Text
                SiteCodeID = $SiteCodeTextBox.Text
                CollectionName = $ColNameTextBox.Text
                CSVFile = $CSVTextBox.Text
            }
            $Object = New-Object -TypeName psobject -Property $Hash
             return $Object
            }
        }
}

function New-ADGroupQuery{
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$GroupName,
        [parameter(HelpMessage = "Enter Collection ID")]
        [string]$CollectionID,
        [Parameter(HelpMessage = "Collection Name")]
        [string]$CollectionName
        )
        try{
            if($CollectionName){
                Write-log -Message "Collection Name option was chosen"
                $GroupName = "$((Get-ADDomain).Name)\\$GroupName"
                Write-Log -Message "Validating if the rule already exists..."
                if($null -ne $(Get-CMDeviceCollectionQueryMembershiprule -RuleName "All devices that are a member of AD Group $($GroupName)" -CollectionName $CollectionName)){
                    Write-Error "A collection rule for this already exists. Do not re-create the rule" -ErrorAction Stop
                }
                Write-Log -Message "The rules does NOT already exist! Willing to create!"
                Write-log -Message "Group Name has been set as $($GroupName)"
                $Query = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "$groupName"
"@
                Write-log -Message "The query was built as $($Query)"
                Add-CMDeviceCollectionQueryMembershiprule -CollectionName $CollectionName -RuleName "All devices that are a member of AD Group $($GroupName)" -QueryExpression $Query -Verbose:$false -ErrorAction Stop
                Write-log -Message "We ran the attempted add now validating it was added"
                if($null -ne $(Get-CMDeviceCollectionQueryMembershiprule -RuleName "All devices that are a member of AD Group $($GroupName)" -CollectionName $CollectionName)){
                    Write-Log "The collection rule was created."   
                }    
            }
            if($CollectionID){
                Write-log -Message "Collection ID option was chosen"
                $GroupName = "$((Get-ADDomain).Name)\\$GroupName"
                Write-Log -Message "Validating if the rule already exists..."
                if($null -ne $(Get-CMDeviceCollectionQueryMembershiprule -RuleName "All devices that are a member of AD Group $($GroupName)" -CollectionID $CollectionID)){
                    Write-Error "A collection rule for this already exists. Do not re-create the rule" -ErrorAction Stop
                }
                Write-log -Message "Group Name has been set as $($GroupName)"
                $Query = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "$groupName"
"@
                Write-log -Message "The query was built as $($Query)"
                Add-CMDeviceCollectionQueryMembershiprule -CollectionID $CollectionID -RuleName "All devices that are a member of AD Group $($GroupName)" -QueryExpression $Query -Verbose:$false -ErrorAction Stop
                Write-log -Message "We ran the attempted add now validating it was added"
                if($null -ne $(Get-CMDeviceCollectionQueryMembershiprule -RuleName "All devices that are a member of AD Group $($GroupName)" -CollectionName $CollectionName)){
                    Write-Log "The collection rule was created."   
                }      
            }
        }
        catch{
            Write-Log -Message "Something went wrong attempting to add $($GroupName) to the CollectionID:$($CollectionID) or CollectionName:$($CollectionName) please try again and use the validate options." -LogLevel 3
        }
    }
}

process{
    Set-DefaultLogPath
    Write-Log -Message "Now starting the AD AdGroup Query Process block"
    $StartingLocation = $(Get-Location).Path
    Write-Log -Message "Collected the Startingpath and stored it as $($StartingLocation)"
    if(Test-ConfigMgrAvailable -Remediate:$true){
        Write-Log -Message "Now completed inital validation steps"
        if(-not $NOGUI){
            $Information = Get-Information
            if($Information){
                Write-log -Message "Now entering the information validation steps."
                if($Information.CSVFile -ne ""){
                    Write-log -Message "Validated that a CSV file was presented"
                    $ColDataSet = import-csv -path $Information.CSVFile
                    Write-log -Message "Imported the CSV data"
                    foreach($Colitem in $ColDataSet){
                        if($Colitem.collectionID -eq $null){
                        #New-ADGroupQuery -GroupName $ColItem.GroupName -CollectionName $ColItem.CollectionName
                        Write-log -Message "#New-ADGroupQuery -GroupName $($ColItem.GroupName) -CollectionName $($ColItem.CollectionName)"
                        }
                        if($Colitem.CollectionName -eq $null){
                            #New-ADGroupQuery -GroupName $ColItem.GroupName -CollectionID $ColItem.CollectionID
                        Write-log -Message "#New-ADGroupQuery -GroupName $($ColItem.GroupName) -CollectionID $($ColItem.CollectionID)"
                        }
                    }
                }
                if($Information.CSVFile -eq ""){
                    Write-log -Message "No CSV File was provided assuming single event"
                    Write-log -Message "Retrieved $($information.collectionID) and $($information.GroupName)"
                    #ENHANCE: Add a notification that this process completes succesfully and re-open the form if needed?
                    New-ADGroupQuery -GroupName $($Information.GroupName) -CollectionName $($Information.CollectionName)
                }
            }
        }
        if($NOGUI){
            Write-Log -Message "The No GUI Option was selected proceeding with values: $($ADGroupName) for AD Group and $($CollectionID) for collection"
            New-ADGroupQuery -GroupName $ADGroupNAme -CollectionID $CollectionID
        }
        Set-location $StartingLocation
    }
}