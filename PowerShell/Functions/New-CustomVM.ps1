<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Untitled-1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-05-13
          Modified: 2019-05-13

          Version - 0.0.0 - (2019-05-13)


          TODO:
               [ ] Script Main Goal
               [ ] Script Secondary Goal

.Example

#>

[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Enter the VMName if you do not enter a VMName then one will be auto generated for you using the formula TestVM_*",Mandatory = $false )]
    [string]$VMName = "TestVM_",
    [Parameter(HelpMessage = "Enter the name of the virtual name of the switch you would like to use",Mandatory = $false)]
    [string]$VMSwitch = "Wireless External",
    [Parameter(HelpMessage = "Enter the folder path to where you would like to store the VHDX",Mandatory = $false)]
    [string]$NewVHDPAth = "D:\VirtualMachines",
    [Parameter(HelpMessage = "Enter the path where you would like the machine resources to live",Mandatory = $false)]
    [string]$NewPath = "D:\VirtualMachines"
)
begin{
    function Write-TsxOutPut{
        <#
            .SYNOPSIS 
                This function is designed to allow someone who is first learning PowerShell to make better calls back to the host screen without
                needing to understand all of the ins and outs of Write-Error / Verbose / Warnings. This also allows you to bypass things like write-host completely.
            
            .DESCRIPTION
                This function can be called through out a script to show visual progress to a user of where the script is at when it's running. This is useful as it does not 
                trigger terminating error code messages or true 'warnings' that otherwise might be caused by a .NET write-error or other method. Also allows the user to color co-ordinate messages
                without using the write-host prompt.
            
            .NOTES
                    FileName:    Write-TsxOutput.PS1
                    Author:      Jordan Benzing
                    Contact:     @JordanTheItGuy
                    Created:     2019-04-11
                    Updated:     2019-04-11
        
                    Version 0.0.0 (2019-04-10) - Wrote original function with no comments and no explanation
                    Version 1.0.0 (2019-04-11) - Wrote function notes into the script added the help section to explain usage
        
            .LINK
                https://github.com/JordanTheITGuy/ProblemResolution/blob/master/PowerShell/Functions/write-TsxOutput.ps1
            
            .PARAMETER MsgLevel
                This parameter only accepts a set of choices you can use the "Tab Key" to rotate through the options. The options are:
                Warning - Sets the font color to Yellow to indicate it didn't do what you wanted but didnt fail either
                Default - Sets the font color to Cyan - a neutral color that is readable and conveys progress
                Success - Sets the font color to green - You did something you wanted or a function completed succesfully
        
            .PARAMETER Message
                This parameter accepts strings and allows you to pass through strings that are supposed to be displayed in a specific color to convey status. 
        
            .EXAMPLE 
                Write-TsxOutPut -MsgLevel Warning -Message "Something is amiss"
                Example of running the code to generate a warning level message - or maybe it just indicates a tricky part is happening
        
            .EXAMPLE
                Write-TsxOutPut -MsgLevel Default -Message "This is normal execution"    
                Example of normal execution message back to the user. 
                
            .EXAMPLE
                Write-TsxOutPut -MsgLevel Success -Message "You made it"
                Example of success or finalized out put message it's green and happy.
        #>
            [cmdletbinding()]
            Param(
            [Parameter(Mandatory = $true,
            HelpMessage = "You must select one of these options, this is what sets the color of the output message from Yellow, Cyan, or Green.")]
            [validateSet("Warning","Default","Success")]
            [string]$MsgLevel,
            [Parameter(Mandatory = $true,
            HelpMessage = "This parameter accespts a string that should be printed in the color font you would like to use")]
            [string]$Message = $false
            )
            #Start the try block
            try{
                #Capture the original state of the foreground for text in line
                $originState = $Host.UI.RawUI.ForegroundColor
                #Start a switch to evaluate the msg level
                switch ($MsgLevel) {
                    "Warning" { 
                        #If the type is warning then set the font to Yellow
                        $Host.UI.RawUI.ForegroundColor = "Yellow"
                        #Write the message using write-output and string concat
                        Write-Output "$($Message)"
                    }
                    "Default"{
                        #If the type is default or 'running as expected" then set the font color to cyan
                        $Host.UI.RawUI.ForegroundColor = "Cyan"
                        #Write the message using write-output and string concat
                        Write-Output "$($Message)"
                    }
                    "Success"{
                        #If the type is Success or 'running as expected" then set the font color to cyan
                        $Host.UI.RawUI.ForegroundColor = "Green"
                        #Write the message using write-output and string concat
                        Write-Output "$($Message)"
                    }
                    #Default should never be triggered as this uses a Validate Set statement
                    Default {}
                }
            }
            #In the even that something goes wrong with the write-output such as an object or something other than a string is properly passed through write an error. 
            catch{
                Write-Error -Message "Something went wrong"
            }
            finally{
                #Always set the color back. 
                $Host.UI.RawUI.ForegroundColor = $originState
            }
        }
        
    function New-CustomVM {
        [CmdletBinding()]
        param()
        Write-Verbose -Message "The VMDoes NOT Exist now creating it"
        New-VM -Name $VMName -MemoryStartupBytes 4294967296 -Generation 2 -NewVHDPath "$($NewVHDPAth)$($VMName)\$($VMName).vhdx" -NewVHDSizeBytes 53687091200 -Path "$($NewPath)" -SwitchName $VMSwitch -ErrorAction Stop | Out-Null
        Write-Verbose -Message "VM Has been created"
        Write-Verbose -Message "Now disabling automatic checkpoints"
        Set-VM -Name $VMName -AutomaticCheckpointsEnabled $false -ErrorAction Stop
        Write-Verbose -Message "Automatic Checkpoints have been disabled"
        Write-Verbose -Message "Now increasing proc to meet standards"
        Set-VMProcessor $VMName -Count 2 -ErrorAction Stop
        Write-Verbose -Message "Configured the Processor to match standards"
        Write-Verbose -Message "Now setting dynamice memory"
        Set-VMMemory -VMname $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 4GB -MaximumBytes 4GB 
        Write-Verbose -Message "Configured dynamic memory"
        Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
        Write-Verbose -Message "Key Protector Set"
        Enable-VMTPM -VMName $VMName
        Write-Verbose -Message "Enabled the TPM"
        write-TsxOutput -MsgLevel success -Message "Succesfully created the virtual machine $($VMName)"
    }
}

process{

if($VMName -ieq "TestVM_"){
    $Count = 0
    Do{
        try {
            $VMName = "$($VMName)$($Count)"
            Write-Verbose -Message "Starting loop to look for possible names current name is $($VMName)"
            Write-Verbose -Message "The VM Name is $($VmNAme)"
            Write-Verbose -Message "Now checking if the VM Exists"
            $TestVMExist = Get-VM -VMName $VMName -ErrorAction SilentlyContinue
            if(-not ($TestVMExist)){
                New-CustomVM
                $break = $true
            }
            if($TestVMExist){
                Write-Verbose -Message "The Virtual Machine $($VMName) exists incrementing"
                Write-Error -Message "The VM Exists throwing and silently continuing" -ErrorAction Stop
            }
        }
        catch {
            $Count++
        }
    }
    until ($break -eq $true)
    }
}