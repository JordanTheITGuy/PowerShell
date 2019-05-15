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
    function New-CustomVM {
        [CmdletBinding()]
        param()
        New-VM -Name $VMName -MemoryStartupBytes 4294967296 -Generation 2 -NewVHDPath "$($NewVHDPAth)\$($VMName)\$($VMName).vhdx" -NewVHDSizeBytes 53687091200 -Path "$($NewPath)\" -SwitchName $Switch -ErrorAction stop | Out-Null
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
        Write-Output "Succesfully created the virtual machine $($VMName)"
    }
}

process{

if($VMName -ieq "TestVM_"){
    $Count = 0
    Do{
        $VMName = "$($VMName)$($Count)"
        Write-Verbose -Message "Starting loop to look for possible names current name is $($VMName)"
        try {
            Write-Verbose -Message "The VM Name is $($VmNAme)"
            Write-Verbose -Message "Now checking if the VM Exists"
            $TestVMExist = Get-VM -VMName $VMName -ErrorAction SilentlyContinue
            if(-not ($TestVMExist)){
                Write-Verbose -Message "The VMDoes NOT Exist now creating it"
                New-CustomVM
                $break = $true
            }
        }
        catch {
            $Count++
        }
    }
    until ($break -eq $true)
    }
}