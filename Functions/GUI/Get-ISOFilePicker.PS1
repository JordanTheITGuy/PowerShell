<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: Get-ISOFilePicker.PS1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-04-30
          Modified: 2019-04-30

          Version - 0.0.0 - (2019-04-30) - Initial version - works fine

          MIT - License:
          THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
          FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
          WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

          TODO:
               [X] Create A file picker object that only allows the user to pick an ISO file

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
        Filter = 'ISO FILE (*.ISO)|*.ISO'}
    $MessageBox.Show('hello')
    $FileBrowserISO.ShowDialog() | out-null
    return $FileBrowserISO.FileName