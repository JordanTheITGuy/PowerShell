<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Untitled-1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-10-10
          Modified: 2019-10-10

          Version - 0.0.0 - (2019-10-10)


          TODO:
               [ ] Script Main Goal
               [ ] Script Secondary Goal

.EXAMPLE

#>

[cmdletbinding()]
param()
begin{

#region helperfunctions
function Get-CMModule
#This application gets the configMgr module
{
    [CmdletBinding()]
    param()
    Try
    {
        Write-Verbose "Attempting to import SCCM Module"
        #Retrieves the fcnction from ConfigMgr installation path. 
        Import-Module (Join-Path $(Split-Path $ENV:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -Verbose:$false
        Write-Verbose "Succesfully imported the SCCM Module"
    }
    Catch
    {
        Throw "Failure to import SCCM Cmdlets."
    } 
}

function Test-ConfigMgrAvailable
#Tests if ConfigMgr is availble so that the SMSProvider and configmgr cmdlets can help. 
{
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
            write-Verbose "ConfigurationManager Module is loaded"
            Write-Verbose "Checking if current drive is a CMDrive"
            if((Get-location -Verbose:$false).Path -ne (Get-location -PSProvider 'CmSite' -Verbose:$false).Path)
            #Checks if the current location is the - PS provider for the CMSite server. 
            {
                Write-Verbose -Message "The location is NOT currently the CMDrive"
                if($Remediate)
                #If the remediation field is set then it attempts to set the current location of the path to the CMSite server path. 
                    {
                        Write-Verbose -Message "Remediation was requested now attempting to set location to the the CM PSDrive"
                        Set-Location -Path (((Get-PSDrive -PSProvider CMSite -Verbose:$false).Name) + ":") -Verbose:$false
                        Write-Verbose -Message "Succesfully connected to the CMDrive"
                        #Sets the location properly to the PSDrive.
                    }

                else
                {
                    throw "You are not currently connected to a CMSite Provider Please Connect and try again"
                }
            }
            write-Verbose "Succesfully validated connection to a CMProvider"
            return $true
        }
        catch
        {
            $errorMessage = $_.Exception.Message
            write-error -Exception CMPatching -Message $errorMessage
            return $false
        }
}

function Test-Module
#Function that is designed to test a module if it is loaded or not. 
{
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
        Write-Verbose -Message "The module was already loaded return TRUE"
        return $true
    }
    If((Get-Module -Name $ModuleName) -ne $true)
    #Checks if the module is NOT loaded and if it's not loaded then check to see if remediation is requested. 
    {
        Write-Verbose -Message "The Module was not already loaded evaluate if remediation flag was set"
        if($Remediate -eq $true)
        #If the remediation flag is selected then attempt to import the module. 
        {
            try 
            {
                    if($ModuleName -eq "ConfigurationManager")
                    #If the module requested is the Configuration Manager module use the below method to try to import the ConfigMGr Module.
                    {
                        Write-Verbose -Message "Non-Standard module requested run pre-written function"
                        Get-CMModule
                        #Runs the command to get the COnfigMgr module if its needed. 
                        Write-Verbose -Message "Succesfully loaded the module"
                        return $true
                    }
                    else
                    {
                    Write-Verbose -Message "Remediation flag WAS set now attempting to import module $($ModuleName)"
                    Import-Module -Name $ModuleName
                    #Import  the other module as needed - if they have no custom requirements.
                    Write-Verbose -Message "Succesfully improted the module $ModuleName"
                    Return $true
                    }
            }
            catch 
            {
                Write-Error -Message "Failed to import the module $($ModuleName)"
                Set-Location $StartingLocation
                break
            }
        }
        else {
            #Else return the fact that it's not applicable and return false from the execution.
            {
                Return $false
            }
        }
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
    $GroupPicker.AcceptButton = $OKButton
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
        return $X
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
    $CollectionPicker.AcceptButton = $OKButton
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
        return $X
    }
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
            $objForm = New-Object System.Windows.Forms.Form 
            $objForm.Text = "SCConfigMgr - Add AD Group Query Rule To Collection"
            $objForm.Icon = "$(split-path $script:MyInvocation.MyCommand.Path)\SCConfigMgrLogo-Square.ico"
            $objForm.BackColor = [System.Drawing.Color]::LightGray
            $objForm.Size = New-Object System.Drawing.Size(480,300) 
            $objForm.StartPosition = "CenterScreen"
        
            $objForm.KeyPreview = $True
            $objForm.Add_KeyDown({
                if ($_.KeyCode -eq "Enter" -or $_.KeyCode -eq "Escape"){
                    $objForm.Close()
                }
            })
        
            #OK Button
            $OKButton = New-Object System.Windows.Forms.Button
            $OKButton.Location = New-Object System.Drawing.Size(10,225)
            $OKButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $OKButton.Size = New-Object System.Drawing.Size(75,23)
            $OKButton.Text = "OK"
            $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $objForm.AcceptButton = $OKButton
            $OKButton.Add_Click({
                $objForm.Close()
            })
            $objForm.Controls.Add($OKButton)
            
            #Cancel Button
            $CancelButton = New-Object System.Windows.Forms.Button
            $CancelButton.Location = New-Object System.Drawing.Size(375,225)
            $CancelButton.Size = New-Object System.Drawing.Size(75,23)
            $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $CancelButton.Text = "Cancel"
            $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $CancelButton = $CancelButton
            $CancelButton.Add_Click({
                $objForm.Close()
             })
            $objForm.Controls.Add($CancelButton)
                  
            ###ADGroup Information###
            $GroupLabel = New-Object System.Windows.Forms.Label
            $GroupLabel.Location = New-Object System.Drawing.Size(10,20) 
            $GroupLabel.Size = New-Object System.Drawing.Size(315,20) 
            $GroupLabel.Text = "Enter The Group Name - Supports wildcards"
            $GroupLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $objForm.Controls.Add($GroupLabel) 
        
            $GroupTextBox= New-Object System.Windows.Forms.TextBox 
            $GroupTextBox.Location = New-Object System.Drawing.Size(10,40) 
            $GroupTextBox.Size = New-Object System.Drawing.Size(315,20)
            $GroupTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $GroupTextBox.Text = ""
            $objForm.Controls.Add($GroupTextBox)
            
            ###AD Group Search###
            $SearchADButton = New-Object System.Windows.Forms.Button
            $SearchADButton.Location = New-Object System.Drawing.Size(375,40)
            $SearchADButton.Size = New-Object System.Drawing.Size(75,23)
            $SearchADButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $SearchADButton.Text = "Search"
            $SearchADButton.Add_Click({                
                if(Test-ConfigMgrAvailable -Remediate:$True){
                    $StartingLocation = $(Get-Location).Path
                    if($SiteCodeTextBox.Text -eq $(Get-PSDrive | Where-Object {$_.Provider -match "CMSite"}).Name){
                        $ADGroup = $GroupTextBox.Text
                        if($ADGroup.Length -gt '0'){
                            if($ADGroup.Substring($ADGroup.Length -1) -eq "*"){
                                $ADGroup = "$($ADGroup.Substring(0,$ADGroup.Length-1))%"
                            }
                        }
                        $ADGroup = Get-WmiObject -Namespace "Root\SMS\site_$($SiteCodeTextBox.Text)" -Query "select distinct name,UserGroupName from SMS_R_UserGroup where UserGroupName like '$($ADGroup)'"
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
                }
                Set-location $StartingLocation
            })
            $objForm.Controls.Add($SearchADButton)

            ###Collection ID Information###
            $CollectionLabel = New-Object System.Windows.Forms.Label
            $CollectionLabel.Location = New-Object System.Drawing.Size(10,70) 
            $CollectionLabel.Size = New-Object System.Drawing.Size(135,20) 
            $CollectionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionLabel.Text = "Enter Collection ID     OR"
            $objForm.Controls.Add($CollectionLabel)
        
            $CollectionIDTextBOX = New-Object System.Windows.Forms.TextBox 
            $CollectionIDTextBOX.Location = New-Object System.Drawing.Size(10,90) 
            $CollectionIDTextBOX.Size = New-Object System.Drawing.Size(120,20) 
            $CollectionIDTextBOX.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $CollectionIDTextBOX.AutoSize = $True
            $CollectionIDTextBOX.Text = ""
            $objForm.Controls.Add($CollectionIDTextBOX)
        
            ###Collection Name Info###

            $ColNameLabel = New-Object System.Windows.Forms.Label
            $ColNameLabel.Location = New-Object System.Drawing.Size(145,70) 
            $ColNameLabel.Size = New-Object System.Drawing.Size(200,20) 
            $ColNameLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $ColNameLabel.Text = "Collection Name - Supports Wildcards"
            $objForm.Controls.Add($ColNameLabel)

            $ColNameTextBox = New-Object System.Windows.Forms.TextBox
            $ColNameTextBox.Location = New-Object System.Drawing.Size(150,90) 
            $ColNameTextBox.Size = New-Object System.Drawing.Size(175,20)
            $ColNameTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $ColNameTextBox.AutoSize = $True
            $ColNameTextBox.Text = ""
            $objForm.Controls.Add($ColNameTextBox)

            ###Search Button###
            $SearchCollButton = New-Object System.Windows.Forms.Button
            $SearchCollButton.Location = New-Object System.Drawing.Size(375,90)
            $SearchCollButton.Size = New-Object System.Drawing.Size(75,23)
            $SearchCollButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $SearchCollButton.Text = "Search"
            $SearchCollButton.Add_Click({
                if(Test-ConfigMgrAvailable -Remediate:$True){
                    $StartingLocation = $(Get-Location).Path
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
                    set-location $STartingLocation
                }
            })
            $objForm.Controls.Add($SearchCollButton)

             <#
            #Validation 
            $ValidateButton = New-Object System.Windows.Forms.Button
            $ValidateButton.Location = New-Object System.Drawing.Size(375,90)
            $ValidateButton.Size = New-Object System.Drawing.Size(75,23)
            $ValidateButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            $ValidateButton.Text = "Validate"
            $ValidateButton.Add_Click({
                if(Test-ConfigMgrAvailable -Remediate:$True){
                    $StartingLocation = $(Get-Location).Path
                    #Validate the Collection Name
                    $Name = Get-CMDeviceCollection -Id $CollectionIDTextBOX.Text | Select-object -ExpandProperty Name
                    if($Name){
                        $ColNameTextBox.Text = $Name
                        #Update The Collection Name
                        $ColNameTextBox.Refresh()
                    }
                    else{
                        $ColNameTextBox.Text = "COLLECTION NOT FOUND"
                        $ColNameTextBox.Refresh()
                    }
                    #Validate the AD Group Exists in ConfigMgr
                    $ADGroup = Get-WmiObject -Namespace "Root\SMS\site_$($SiteCodeTextBox.Text)" -Query "select distinct name,UserGroupName from SMS_R_UserGroup where UserGroupName ='$($GroupTextBox.Text)'"
                    if($ADGroup){
                        $GroupTextBox.Text = $ADGroup.UserGroupName
                        $GroupTextBox.Update()
                    }
                    Else{
                        $GroupTextBox.Text = "GROUP NOT FOUND"
                    }
                    Set-location $StartingLocation
                }
             })
            $objForm.Controls.Add($ValidateButton)
            #>
                  
            ###Site Server ID ###
            $SiteCodeLabel = New-Object System.Windows.Forms.Label
            $SiteCodeLabel.Location = New-Object System.Drawing.Size(10,120) 
            $SiteCodeLabel.Size = New-Object System.Drawing.Size(315,20) 
            $SiteCodeLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            $SiteCodeLabel.Text = "Specify the Site Server ID"
            $objForm.Controls.Add($SiteCodeLabel)
        
             
           $SiteCodeTextBox = New-Object System.Windows.Forms.TextBox 
           $SiteCodeTextBox.Location = New-Object System.Drawing.Size(10,140) 
           $SiteCodeTextBox.Size = New-Object System.Drawing.Size(315,20) 
           $SiteCodeTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
           $SiteCodeTextBox.AutoSize = $True
           if(Test-ConfigMgrAvailable -Remediate:$True){
                $StartingLocation = $(Get-Location).Path
                $CMSiteCode = $(Get-PSDrive | Where-Object {$_.Provider -match "CMSite"}).Name
           }
           $SiteCodeTextBox.Text = "$CMSiteCode"
           $objForm.Controls.Add($SiteCodeTextBox)
        
            $objForm.Topmost = $True
            $objForm.Add_Shown({$objForm.Activate()})
            $Result = $objForm.ShowDialog()
            if($Result -eq [System.Windows.Forms.DialogResult]::OK){
            $Hash = @{
                GroupName = $GroupTextBox.Text
                collectionID = $CollectionIDTextBOX.Text
                SiteCodeID = $SiteCodeTextBox.Text
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
        [parameter(Mandatory = $true)]
        [string]$CollectionID
        )
$GroupName = "$((Get-ADDomain).Name)\\$GroupName"
$Query = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "$groupName"
"@
        Add-CMDeviceCollectionQueryMembershiprule -CollectionID $CollectionID -RuleName "All devices that are a member of AD Group $($GroupName)" -QueryExpression $Query
}
}
process{
    $StartingLocation = $(Get-Location).Path
    if(Test-ConfigMgrAvailable -Remediate:$true){
    $Information = Get-Information
    if($Information){
        #New-ADGroupQuery -GroupName $Information.GroupName -CollectionID $Information.collectionID
    }
    Set-location $StartingLocation
    }
}