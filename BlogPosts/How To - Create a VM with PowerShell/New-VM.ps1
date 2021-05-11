[CmdletBinding()]
param(
    [Parameter(HelpMessagle = "Enter the VMName" , Mandatory = $true)]
    [string]$ClientName,
    [Parameter(HelpMessage = "Enter the VMPath" , Mandatory = $false)]
    [string]$VMPath = "E:\Hyper-V",
    [Parameter(HelpMessage = "Enter the number of cores you would like" , Mandatory = $FALSE)]
    [Int32]$CoreCount = 2,
    [Parameter(HelpMessage = "Enter the vlanID" , Mandatory = $FALSE)]
    [Int32]$vlanID = 101
)

New-VM -Name $ClientName -path "$VMPath\$ClientName" -MemoryStartup 4GB -BootDevice NetworkAdapter -Generation 2 -NewVHDSizeBytes 40GB -NewVHDPath "$VMPath\$ClientName\$($ClientName).vhdx" -SwitchName "EXTERNAL"
Set-VMNetworkAdapterVlan -VMName $ClientName -Access -VlanId $vlanID
Set-VMProcessor -VMName $ClientName -Count $CoreCount