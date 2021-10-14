Set-StrictMode -Version Latest
#####################################################
#  Start-SitecoreLocal
#####################################################
<#
.SYNOPSIS
    Sets a variable in a Local environment (.env) file.
.DESCRIPTION
    Sets a variable in a Local environment (.env) file.
    Assumes .env file is in the current directory by default.
.PARAMETER Variable
    Specifies the variable name.
.PARAMETER Value
    Specifies the variable value.
.PARAMETER Path
    Specifies the Local environment (.env) file path. Assumes .env file is in the current directory by default.
.EXAMPLE
    PS C:\> Start-SitecoreLocal -Variable VAR1 -Value "value one"
.EXAMPLE
    PS C:\> "value one" | Start-SitecoreLocal "VAR1"
.EXAMPLE
    PS C:\> Start-SitecoreLocal -Variable VAR1 -Value "value one" -Path .\src\.env
.INPUTS
    System.String. You can pipe in the Value parameter.
.OUTPUTS
    None.
#>
function Start-SitecoreLocal
{
	[CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Position=0)] # Positional parameter
        [string]$config = "Local-compose.xp.spe",
		[Parameter(Position=1)] # Positional parameter
		[alias("images")]
        [string]$Localimages = "Local-images"
    )
    begin {
		$ErrorActionPreference = 'Stop'

		#Clear-Host
		$VerbosePreference = "SilentlyContinue"

		#$scriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		#$scriptPath = $PSScriptRoot #$MyInvocation.MyCommand.Path
		#$scriptFolder = Split-Path $scriptPath
		
		Write-Verbose "$PSScriptRoot $config started"

		$moduleBase = Get-ModuleBase #$MyInvocation.MyCommand.Module.ModuleBase
		Write-Verbose "moduleBase:$moduleBase"
		$repoPath = $moduleBase
		Write-Verbose "repoPath:$repoPath"

		Push-Location $PSScriptRoot
		#$repoPath = [System.IO.Path]::GetFullPath("$cwd/../../..")
		#$repoPath = System.IO.Path]::GetFullPath(($cwd + "\.." * 3))
		#$repoPath = (Get-Item $cwd).parent.parent.parent.FullName
		#$reposPath = Split-Path (Split-Path (Split-Path $scriptPath -Parent) -Parent) -Parent
		Write-Verbose "reposPath:$reposPath"
	}
	process {
		try {
			#TODO: Check if it needs to do Build-SitecoreLocal first and call it
			#Build-SitecoreLocal
    	    Set-Location "$reposPath\$Localimages\build\windows\tests\9.3.x"
			if($PSCmdlet.ShouldProcess($config)) {
				Set-SitecoreLocalLicense
	        	Local-compose -f "$config.yml" up
				#TODO: Launch browser?
			}
        }
        finally {
            Pop-Location
        }
    }
}