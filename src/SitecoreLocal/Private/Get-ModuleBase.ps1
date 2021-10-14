Set-StrictMode -Version Latest
#####################################################
#  Get-ModuleBase
#####################################################
<#
.SYNOPSIS
    Sets a variable in a Docker environment (.env) file.
.DESCRIPTION
    Sets a variable in a Docker environment (.env) file.
    Assumes .env file is in the current directory by default.
.PARAMETER Variable
    Specifies the variable name.
.PARAMETER Value
    Specifies the variable value.
.PARAMETER Path
    Specifies the Docker environment (.env) file path. Assumes .env file is in the current directory by default.
.EXAMPLE
    PS C:\> Get-ModuleBase -Variable VAR1 -Value "value one"
.EXAMPLE
    PS C:\> "value one" | Get-ModuleBase "VAR1"
.EXAMPLE
    PS C:\> Get-ModuleBase -Variable VAR1 -Value "value one" -Path .\src\.env
.INPUTS
    System.String. You can pipe in the Value parameter.
.OUTPUTS
    None.
#>		
function Get-ModuleBase
{
	$ErrorActionPreference = 'Stop'

	#Clear-Host
	$VerbosePreference = "Continue"

	$scriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$scriptPath = $PSScriptRoot #$MyInvocation.MyCommand.Path
	$moduleName = Split-Path (Split-Path $scriptPath -Parent) -Leaf
	Write-Verbose "$scriptName started:$pwd"
	$moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
	$ndx = $moduleBase.IndexOf($moduleName)
	if($ndx -ne -1) {$moduleBase = $moduleBase.Substring(0, $ndx + $moduleName.Length)}
	Write-Verbose "moduleBase:$moduleBase"
	return $moduleBase
}
