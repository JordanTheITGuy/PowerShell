[cmdletbinding()]
param(
    [Parameter(HelpMessage = "Provide the or CN Path you would like to modify." )]
    [string]$OUPath,
    [Parameter(HelpMessage = "Provide the AD User name you would like to add" )]
    [string]$UserName
)
begin{}
process{
#Provide AD group Name here
try{
    Import-Module ActiveDirectory -ErrorAction Stop
    $User = Get-ADUser -Identity $UserName -ErrorAction Stop
}
Catch{
    Write-Verbose -Message "You tried to use a group that doesn't exist no changes were made exiting"
    break  
}
#Retrive the current ACL list for the Systm Management Container or container of your choice
$acl = get-acl "ad:$($OUPath)"
#REtrieve the SID of the Group Name and create a SID object to conain it
$SID = New-Object System.Security.Principal.SecurityIdentifier $User.SID
#Create an ACE object that contains the appropraite permissions
$ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $Sid,"GenericAll","all"
#Apply the ACE to the ACL list that was retrieved
$ACL.AddAccessRule($ace)
#Set the ACL on the System Management container or the container of your choice
Set-acl -aclobject $acl "ad:$($OUPath)"
}
