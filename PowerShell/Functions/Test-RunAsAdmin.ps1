<#
.SYNOPSIS
    Function to determin if the current running user is an administrator    

.DESCRIPTION
    Function script that determines if the current running user is or is not an administrator. This can be copy pasted into other scripted
    This script can also be loaded via Dot Sourcing. 

.LINK
    https://github.com/JordanTheITGuy/ProblemResolution/tree/master/PowerShell/Functions

.NOTES
          FileName: Test-RunAsAdmin.ps1
          Author: Jordan Benzing
          Contact: @JordanTheItGuy
          Created: 2019-04-22
          Modified: 2019-04-22

          Version - 0.0.0 - (2019-04-22) - Script/Function works as intended.
          
          MIT - License:
          THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
          FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
          WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
          
          TODO:
               [X] Check if current user is running in Admin Context
               

.Example
    . .\Test-RunAsAdmin.Ps1
    C:\> Test-RunAsAdmin
    False

#>
function Test-RunAsAdmin{
    [cmdletbinding()]
    param()
    begin{}
    process{
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if(!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){
            return $false
        }
        return $true
    }
}