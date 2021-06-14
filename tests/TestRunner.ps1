param(
    [Parameter(HelpMessage="The block of tests to run in the scope of the module")]
    [ScriptBlock]$TestScope
)
$scriptPath = $MyInvocation.MyCommand.Path
$repoPath = Split-Path (Split-Path $scriptPath -Parent) -Parent
$moduleName = Split-Path $repoPath -Leaf
if (Get-Module $moduleName -ErrorAction SilentlyContinue) {
    Remove-Module $moduleName -Force
}
Clear-Host
Import-Module "$repoPath\src\$ModuleName\$moduleName.psm1" -Force -Scope Global -ErrorAction Stop
InModuleScope $moduleName $TestScope