function Write-TsxOutPut{
    Param(
    [Parameter(Mandatory = $true)]
    [validateSet("Warning","Default","Success")]
    [string]$MsgLevel,
    [Parameter(Mandatory = $true)]
    [string]$Message = $false
    )
    try{
        $originState = $Host.UI.RawUI.ForegroundColor
        switch ($MsgLevel) {
            "Warning" { 
                $Host.UI.RawUI.ForegroundColor = "Yellow"
                Write-Output "$($Message)"
            }
            "Default"{
                $Host.UI.RawUI.ForegroundColor = "Cyan"
                Write-Output "$($Message)"
            }
            "Success"{
                $Host.UI.RawUI.ForegroundColor = "Green"
                Write-Output "$($Message)"
            }
            Default {}
        }
    }
    catch{
        Write-Error -Message "Something went wrong"
    }
    finally{
        $Host.UI.RawUI.ForegroundColor = $originState
    }
}


Write-TsxOutPut -MsgLevel Warning -Message "Something is amiss"
Write-TsxOutPut -MsgLevel Default -Message "This is normal execution"
Write-TsxOutPut -MsgLevel Success -Message "You made it"

    