<#
.SYNOPSIS
    This script is designed to get and break down an Active Directory Groups Membership recursively

.DESCRIPTION
    While the ActiveDirectory module supports a recurse module it does not recursively search inside of returned
    Groups until it finds the bottom of the tree structure. This script was written with this idea in mind. 
    This script is an update to to a script written buy Jordan The IT guy years ago. 

.LINK
    https://jordantheitguy.com/


.NOTES
          FileName: Get-NestedMembership.ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-12-26
          Modified: 2019-12-26

          Version - 0.1.0 - (2019-12-26)


          TODO: Replicate the previous script functionality 
          TODO: Make the sccript more modern with PowerShell 5.1 functionality
          TODO: Make an array - That tracks the job status
               
.EXAMPLE

#>
#Requires -Module ActiveDirectory 
#Requires -version 5.1

[cmdletbinding()]
param(
    [Parameter(HelpMessage = "This parameter specifices the name of the AD Group you would like to query for memberhsip.")]
    [string]$GroupName = "GroupA"
)
begin { 
    function New-Arrays {
        [cmdletbinding()]
        param(
            [Parameter(HelpMessage = "Specify the name of the array object to be created.")]
            [string]$ArrayName
        )
        $ArrayName = New-Object -TypeName System.Collections.Generic.List[PSObject]
        return $ArrayName
    }
}
process { 
    $AllMembers = New-Object -TypeName System.Collections.Generic.List[psobject]
    $Membership = Get-ADGroupMember -Identity $GroupName
    foreach($Member in $Membership){
        $HashItem = @{
            SamAccountName = $Member.SamAccountName
            SID = $Member.SID
            Type = $Member.ObjectClass
            DirectParent = $GroupName
        }
        $Object = New-Object -TypeName psobject -Property $HashItem
        $AllMembers.add($Object)
    }
    $GroupBase = New-Object -TypeName System.Collections.Generic.List[psobject]
    $AllMembers | Where-Object {$_.Type -eq 'Group'} |ForEach-Object {$Hash = @{Name = $_.SamAccountName;Analyzed = $False};$GroupBase.Add($(New-Object -TypeName psobject -Property $Hash))}
    Do{
        
    }
    untill (!($GroupBase | Where-Object {$_.Analyzed -eq $false}))

    
}