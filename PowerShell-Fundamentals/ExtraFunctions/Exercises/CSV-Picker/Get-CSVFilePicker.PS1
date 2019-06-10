<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Get-CSVFilePicker.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-04-30
          Modified: 2019-04-30

          Version - 0.0.0 - (2019-06-07)

          MIT - License:
          THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
          FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
          WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

          TODO:
            Properly fill out synopsis/description and a LINK to your github repository.
            Convert the block to a FUNCTION. 
            Using the below code example - Update the filter to ONLY allow it to select CSV Files. 
            Create a NEW function that uses the "Import-CSV" PowerShell Cmdlet to import the contents and write them to the screen. 
            
            Final results should

            1) Begin by loading two functions
            2) Call the function to select a CSV
            3) Import the selected CSV into memory (One is provided)
            4) Write the information from the imported CSV to the screen. 
.Example

#>

[cmdletbinding()]
param(
    [Parameter(HelpMessage ="Enter the message you would like to display before asking the user to make a selection" )]
    [string]$Message
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationFramework
    $msboxReturn = [System.Windows.Forms.MessageBox]::Show("$($Message)","TITLEOFMSGBOX",[System.Windows.Forms.MessageBoxButtons]::OKCancel)
    $FileBrowserISO = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Filter = 'csv FILE (*.csv|*.csv'}
    $FileBrowserISO.ShowDialog() | out-null
    Write-host $FileBrowserISO.FileName
    $List = Import-CSV -path $FileBrowserISO.FileName
    foreach($item in $List){
        $item.FirstName
    }
    
