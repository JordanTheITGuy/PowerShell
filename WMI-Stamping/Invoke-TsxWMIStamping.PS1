<#	

#>
## Functions to be used ##
function New-TsxInventoryInfo
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName,
		[parameter(Mandatory = $true)]
		[string]$BillingCode,
		[parameter(Mandatory = $true)]
		[string]$SupportGroup,
		[parameter(Mandatory = $true)]
		[string]$ServerClass,
		[parameter(Mandatory = $true)]
		[string]$ApprovedChange,
		[parameter(Mandatory = $true)]
		[string]$AIPM,
		[parameter(Mandatory = $true)]
		[string]$SerialNumber
	)
	if (Test-Connectivity -ComputerName $ComputerName)
	{
		Try
		{ $obj = Get-WmiObject -Namespace 'root\TSXInformation' -Class "TSX_Device_Info" -ErrorAction Stop}
		Catch
		{Write-Verbose 'Namespace not found, proceed to creation'}
		If ($obj)
		{
			Write-Verbose "Namespace and class already exist end"
			Throw "The namespace and class already exist. If you are trying to update an existing inventory instance please use the Update-TSXInventoryInfo function"
		}
		Else
		{
			New-TSXNamespace -ComputerName $ComputerName
			$newClass = New-Object System.Management.ManagementClass("root\TSXInformation", [String]::Empty, $null);
			$newClass["__CLASS"] = "TSX_Device_Info";
			$newClass.Qualifiers.Add("static", $true)
			$newClass.Properties.Add("BillingCode", [System.Management.CimType]::String, $false)
			$newClass.Properties["BillingCode"].Qualifiers.Add("read", $true)
			$newClass.Properties["BillingCode"].Qualifiers.Add("write", $true)
			$newClass.Properties["BillingCode"].Qualifiers.Add("key", $true)
			$newClass.Properties.Add("ServerClassification", [System.Management.CimType]::String, $false)
			$newClass.Properties["ServerClassification"].Qualifiers.Add("read", $true)
			$newClass.Properties["ServerClassification"].Qualifiers.Add("write", $true)
			$newClass.Properties["ServerClassification"].Qualifiers.Add("key", $true)
			$newClass.Properties.Add("SupportGroup", [System.Management.CimType]::String, $false)
			$newClass.Properties["SupportGroup"].Qualifiers.Add("read", $true)
			$newClass.Properties["SupportGroup"].Qualifiers.Add("write", $true)
			$newClass.Properties["SupportGroup"].Qualifiers.Add("key", $true)
			$newClass.Properties.Add("ApprovedChange", [System.Management.CimType]::String, $false)
			$newClass.Properties["ApprovedChange"].Qualifiers.Add("read", $true)
			$newClass.Properties["ApprovedChange"].Qualifiers.Add("write", $true)
			$newClass.Properties["ApprovedChange"].Qualifiers.Add("key", $true)
			$newClass.Properties.Add("AIPM", [System.Management.CimType]::String, $false)
			$newClass.Properties["AIPM"].Qualifiers.Add("read", $true)
			$newClass.Properties["AIPM"].Qualifiers.Add("write", $true)
			$newClass.Properties["AIPM"].Qualifiers.Add("key", $true)
			$newClass.Properties.Add("SerialNumber", [System.Management.CimType]::String, $false)
			$newClass.Properties["SerialNumber"].Qualifiers.Add("read", $true)
			$newClass.Properties["SerialNumber"].Qualifiers.Add("write", $true)
			$newClass.Properties["SerialNumber"].Qualifiers.Add("key", $true)
			$newClass.Put() | Out-Null
			Set-WmiInstance -namespace root\TSXInformation -Class TSX_Device_Info -Argument @{ BillingCode = $BillingCode; ServerClassification = $ServerClass; SupportGroup = $SupportGroup; ApprovedChange = $ApprovedChange; AIPM = $AIPM; SerialNumber = $SerialNumber } | Out-Null
		}
		
	}
	Else
	{
		Write-Verbose "Failed Connection test"	
	}
}

function Get-TSXInventoryInfo
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName
	)
	If (Test-Connectivity -ComputerName $ComputerName)
	{
		Try
		{
			Get-WmiObject -Namespace "root\TSXInformation" -Class "TSX_Device_Info" -ErrorAction Stop| select BillingCode, ServerClassification, SupportGroup, ApprovedChange, AIPM, SerialNumber | Ft
		}
		Catch
		{
			throw "The Inventory information for this server does not exist"	
		}
	}
	
}

function Update-TSXInventoryInfo
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName,
		[parameter(Mandatory = $true)]
		[string]$BillingCode,
		[parameter(Mandatory = $true)]
		[string]$SupportGroup,
		[parameter(Mandatory = $true)]
		[string]$ServerClass,
		[parameter(Mandatory = $true)]
		[string]$ApprovedChange,
		[parameter(Mandatory = $true)]
		[string]$AIPM,
		[parameter(Mandatory = $true)]
		[string]$SerialNumber
	)
	$WmiClass = Get-WmiObject -Namespace 'Root\TSXInformation' -Class 'TSX_Device_Info' -List
	$Instances = $WmiClass.GetInstances()
	$Instances.Delete()
	Set-WmiInstance -namespace root\TSXInformation -Class TSX_Device_Info -Argument @{ BillingCode = $BillingCode; ServerClassification = $ServerClass; SupportGroup = $SupportGroup; ApprovedChange = $ApprovedChange; AIPM = $AIPM; SerialNumber = $SerialNumber } | Out-Null
	}
##Supporting Functions unique to this Module##
#############################################
function New-TSXNamespace
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName,
		[Parameter(Mandatory = $false)]
		[string]$Root = "root"
	)
	if (Test-Connectivity -ComputerName $ComputerName)
	{
		try
		{
			$Nspace = $([WMICLASS]"\\$($ComputerName)\$($Root):__Namespace").CreateInstance()
			$Nspace.name = "TSXInformation"
			$Nspace.put() | Out-Null
		}
		catch
		{
			Write-Verbose -Message "Something went wrong creating the namespace"
		}
	}
}

##Supporting Generic Functions##
#############################################
function Test-Connectivity
#Test Connection function. All network tests should be added to this for a full connection test. Returns true or false.
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName
	)
	Try
	{
		Test-Ping -ComputerName $ComputerName -ErrorAction Stop
		Test-AdminShare -ComputerName $ComputerName -ErrorAction Stop
		return $true
	}
	CATCH
	{
		$ConnectionStatus = $false
		Write-Verbose "$ComputerName failed a connection test."
		return $false
	}
}

function Test-Ping
#Test ping for computer.
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName
	)
	$PingTest = Test-Connection -ComputerName $ComputerName -BufferSize 8 -Count 1 -Quiet
	If ($PingTest)
	{
		Write-Verbose "$ComputerName can be pinged"
	}
	Else
	{
		Write-Verbose "$ComputerName failed ping test"
		throw [System.Net.NetworkInformation.PingException] "$ComputerName failed ping test."
	}
}

function Test-AdminShare
#Test Conection to admin C$ share.
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[string]$ComputerName
	)
	$AdminShare = "\\" + $ComputerName + "\C$"
	$AdminAccess = Test-Path -Path $AdminShare -ErrorAction Stop
	if ($AdminAccess)
	{
		Write-Verbose "$ComputerName can be connected too"
		$ConnectionStatus = $true
	}
	Else
	{
		Write-Verbose "$ComputerName admin share not found"
		throw [System.IO.FileNotFoundException] "$ComputerName admin share not found"
		
	}
}
##############################################