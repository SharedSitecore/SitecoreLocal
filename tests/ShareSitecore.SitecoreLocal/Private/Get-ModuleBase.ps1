$repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
. $repoPath\tests\TestRunner.ps1 {
    $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    . $repoPath\tests\TestUtils.ps1

    Describe 'Set-SitecoreDockerLicense.Tests' {

        It 'not null' {
            { Get-ModuleBase } | Should -Not -Throw
        }
    }
}