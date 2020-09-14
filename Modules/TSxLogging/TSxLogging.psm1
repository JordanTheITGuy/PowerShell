<#
.SYNOPSIS
	This Module was created by the Jordan Benzing a member of the Truesec Infrastructure team to address logging.

.DESCRIPTION
    This module is a condensed version of a larger library created by members of the Truesec Infrastructure team that is geared specifically to logging. 
  
.NOTES
    FileName: TSxLogging.psm1
    Author: Jordan Benzing
    Contact: @JordanTheItGuy
    Created: 2020-06-23

    Version - 0.0.1 - 2020-06-23

    License Info:
    MIT License
    Copyright (c) 2020 TRUESEC

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>
Function Write-TSxLog {
<#
.SYNOPSIS
    Logging function that performs the execution of the module. This cmdlet is publically addressible when in use.

.DESCRIPTION
    Use this function to write different types of logs for actions that have been taken in a PowerShell prompt. 

.NOTES

    FunctionName: Write-TSxLog
    Author: Jordan Benzing
    Contact: @JordanTheItGuy
    Created: 2020-06-23

    Version - 0.0.1 - 2020-06-23

    License Info:
    MIT License
    Copyright (c) 2020 TRUESEC

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

.PARAMETER Message
    Enter the body of the message you would like to log

.PARAMETER LogLevel
    Enter the number 1,2,3 where 1 is verbose, 2 is warning 3 is error. May update this later to use the actual terms. 

.PARAMETER WritetoScreen
    Determine if the message that is being logged should be written to the screen or not BOOLEAN. This will display or not display the message generated for the log.

.PARAMETER LogFolderPath
    Enter the path to the log folder you if you are writing multiple logs and what you would like to use as the logs. If you don't specify the temp directory will be used.

.PARAMETER LogFileName 
    Enter the log file name if you want name the log otherwise it will be generated for you.

.EXAMPLE
    Write-TsxLog -Message "Hello World"
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(HelpMessage = "Enter the log level", Mandatory = $false)]
        [ValidateSet(1, 2, 3)]
        [string]$LogLevel = 1,
        [Parameter(HelpMessage = "This variable enables you to turn off writing the logged message to the screen it is on by default." , Mandatory = $false)]
        [bool]$writetoscreen = $false,
        [Parameter(HelpMessage = "Enter the path to the log folder and it will change dynamically")]
        [string]$LogFoldderPath,
        [Parameter(HelpMessage = "Enter the log file name")]
        [string]$LogFileName  
    )
    if ($LogFileName -and $LogFoldderPath) {
        set-TSxLogPath -LogFolderPath $LogFoldderPath -LogFileName $LogFileName
    }
    elseif ($LogFoldderPath) {
        set-TSxLogPath -LogFolderPath $LogFoldderPath
    }
    elseif ($LogFileName) {
        set-TSxLogPath -LogFileName $LogFileName
    }
    if (!($Global:TSxCurrentLogFile)) {
        set-TSxLogPath
    }
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    if ($MyInvocation.ScriptName) {
        $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    }
    else {
        $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "EXECUTED BY:$($ENV:USERNAME)", $LogLevel
    }
    $Line = $Line -f $LineFormat
    [system.GC]::Collect()
    Add-Content -Value $Line -Path $Global:TSxCurrentLogFile -Force
    if ($writetoscreen) {
        switch ($LogLevel) {
            '1' {
                Write-Verbose -Message $Message -Verbose
            }
            '2' {
                Write-Warning -Message $Message
            }
            '3' {
                Write-Error -Message $Message
            }
            Default {
            }
        }
    }
    if ($writetolistbox -eq $true) {
        $result1.Items.Add("$Message")
    }
}

function set-TSxLogPath {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param
    (
        [parameter(Mandatory = $False, ParameterSetName = 'LogName')]
        [string]$LogFolderPath,
        [Parameter(Mandatory = $False, HelpMessage = "Enter the log file name", ParameterSetName = 'LogName')]
        [string]$LogFileName
    )
    begin {
        if (!($Global:TSxDefaultlogFile)) {
            New-Variable -Name TSxDefaultLogFile -Value "$($ENV:TEMP)\TSxModule.log" -Scope Global
        }
    }
    process {
        #region SetLogfileName
        if ($LogFileName) {
            if ($($LogFileName.Substring($($LogFileName.Length - 4)) -eq ".log")) {
                $LogFile = $LogFileName
            }
            else {
                $LogFile = "$($LogFileName).log"
            }
        }
        else {
            if ($script:MyInvocation) {
                $TSxCallStack = Get-PSCallStack
                $LogFile = "$($($TSxCallStack[$TSxCallStack.Length-2].InvocationInfo.MyCommand.Name).Substring(0,$($TSxCallStack[$TSxCallStack.Length-2].InvocationInfo.MyCommand.Name).Length-4)).log"
                $Global:TSxCallStack = $TSxCallStack
            }
            else {
                $LogFile = "TSXModule.log"
                Write-Warning -Message "You are running inside ISE - all commands will be logged to: $($LogFile)"
            }
        }
        #endregion SetLogFileName

        #Region SetLogFolderName
        if ($LogFolderPath) {
            $FullLogFile = "$($LogFolderPath)\$($logFile)"
            if ($(Get-Variable -Name "TSx*" | Where-Object { $_.Value -like "*$($LogFile)" })) {
                $Global:TSxCurrentLogFile = $(Get-Variable -Name "TSX*$($LogFile)" | Where-Object { $_.Value -like "*$($LogFile)" }).Value
            }
            else {
                New-Variable -Name "TSx$($LogFile)" -Scope Global -Value $FullLogFile
                $Global:TSxCurrentLogFile = $(Get-Variable -Name "TSX*$($LogFile)" | Where-Object { $_.Value -like "*$($LogFile)" }).Value
            }
        }
        else {
            if ($(Get-Variable -Name "TSx*" | Where-Object { $_.Value -like "*$($LogFile)" })) {
                $Global:TSxCurrentLogFile = $(Get-Variable -Name "TSX*$($LogFile)" | Where-Object { $_.Value -like "*$($LogFile)" }).Value
            }
            else {
                try {
                    if ($MyInvocation.InvocationName -eq "set-TSxLogPath") {
                        #Write-Warning -Message "You ran the code from a location that caused the invocation path to be equal to the function and caused a filepath violation." -WarningAction Stop
                        throw
                    }
                    else { 
                        $TSxCallStack = Get-PSCallStack
                        $Global:TSxCallStack = $TSxCallStack
                        $Name = $TSxCallStack[-2].InvocationInfo.MyCommand.Name
                        $Source = $TSxCallStack[-2].InvocationInfo.MyCommand.Source
                        $LogFolderPath = $Source.Replace($Name, "")
                        $Global:TSxCurrentLogFile = "$($LogFolderPath)$($Logfile)"
                    }
                }
            catch {
                Write-Warning -Message "$($_.Exception.Message)"
                Write-Warning -Message "You specified a log that doesn't exist, or hasn't been declared and or we can't find the current executing script - all commands will be logged to: $($Global:TSxDefaultlogFile)"
                $Global:TSxCurrentLogFile = $Global:TSxDefaultLogFile
            }
        }
    }
    #endregion SetLogFolderName
    try {
        #Confirm the provided destination for logging exists if it doesn't then create it.
        if (!(Test-Path $Global:TSxCurrentLogFile)) {
            ## Create the log file destination if it doesn't exist.
            New-Item $Global:TSxCurrentLogFile -Type File | Out-Null
        }
    }
    catch {
        #In event of an error write an exception
        Write-Error $_.Exception.Message
    }
}
}