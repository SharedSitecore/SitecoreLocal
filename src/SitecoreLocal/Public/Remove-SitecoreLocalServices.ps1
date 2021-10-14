Set-StrictMode -Version Latest
#####################################################
# Remove-SitecoreLocalServices
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
    PS C:\> Remove-SitecoreLocalServices -Variable VAR1 -Value "value one"
.EXAMPLE
    PS C:\> "value one" | Remove-SitecoreLocalServices "VAR1"
.EXAMPLE
    PS C:\> Remove-SitecoreLocalServices -Variable VAR1 -Value "value one" -Path .\src\.env
.INPUTS
    System.String. You can pipe in the Value parameter.
.OUTPUTS
    None.
#>
function Remove-SitecoreLocalServices
{
	[CmdletBinding(SupportsShouldProcess)]
    Param (
		# Name of new Sitecore Local instance [default=dev]exit
		[Parameter(Mandatory=$false)] [string]$name = '',

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFile = "",

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationRoot = "",

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFileName = "XP0-SitecoreLocal.json"
	)
	begin {
		$ErrorActionPreference = 'Stop'
		$VerbosePreference = 'SilentlyContinue'
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
		Write-Host $parametersResults.output -ForegroundColor Green
		$started = $parametersResults.started

		Write-Host "PSScriptRoot:$PSScriptRoot"

		$PSScriptPath = Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name
		Write-Host "PSScriptPath:$PSScriptPath"

		$PSScriptFolder = Split-Path $PSScriptPath -Parent
		$PSRootDrive = if (Get-PSDrive 'd') { 'd:' } else { 'c:' }
		$PSRepoPath = Split-Path $PSScriptFolder -Parent
		if ($PSRepoPath.IndexOf('src') -ne -1) {
			$PSRepoPath = Split-Path (Split-Path $PSRepoPath -Parent) -Parent
		} else {
			$PSRepoPath = Join-Path $PSRootDrive '\repos\SharedSitecore\SitecoreLocal'
		}
		
		if (!$name) {
			Write-Verbose "Getting name from:$ConfigurationFile"
			$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
			if (!$config) {
				throw "Error trying to load configuration!"
			}
							
			$site = $config.settings.site
			$name = $site.prefix
		}

	}
	process {
		try {
			if($PSCmdlet.ShouldProcess($ConfigurationFile)) {				
				$results = ''
				$services = Get-Service "$name*" -ErrorAction SilentlyContinue
				if ($services) {
					foreach($service in $services) {
						Write-Host "Found service:$service"
						$results += "Remove-Service $service"
						try {
							#Stop-Service $service -Force -ErrorAction SilentlyContinue
							#Remove-Service $service -Force -ErrorAction SilentlyContinue
							sc.exe \\. delete $service
						} catch {
							$results += ":error $_"
						}
					}
				}
				if (!$results) { $results = "No services found:$name" }
				Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show).output
				return $results
			}
		}
		catch {
		  Write-Error "ERROR:$_" -InformationVariable results
		}
		#finally {
		#	Write-Host "#####################################################" -ForegroundColor Green
		#	Write-Host "# $PSScriptName ended successfully" -ForegroundColor Magenta
		#}
	}
	end {
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $started
		Write-Host $parametersResults.output -ForegroundColor Green

		Pop-Location
		#Stop-Transcript
    }
}