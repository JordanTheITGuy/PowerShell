function Test-TSxRoleInstalled
#Tests to see if a particular Windows feature/role is instaled
{
        [CmdletBinding()]
        param
        (
            [parameter(Mandatory = $true)]
            [string]$RoleName,
            [parameter()]
            [string]$ComputerName = $ENV:COMPUTERNAME
        )
        Try
        {
            #write-TSxInstallLog -Message "Now confirming if the role is installed on the machine"
            $FeatureInfo = Get-WindowsFeature -Name $RoleName -ComputerName $ComputerName -Verbose:$false
            if($FeatureInfo.InstallState -eq $true)
            {
                #write-TSxInstallLog -Message "The role is installed on the machine"
                return $true
            }
            else
            {
                #write-TSxInstallLog -Message "The role $($RoleName) is NOT installed on the machine"
                return $false
            }
        }
        Catch
        {
            throw [System.IO.DriveNotFoundException] "An Error occured with detecting the roles installation state"
        }
}