#Set-StrictMode -Version Latest
#####################################################
# Remove-SitecoreLocal
#####################################################
<#PSScriptInfo

.VERSION 0.0

.GUID 602bc07e-a621-4738-8c27-0edf4a4cea8e

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS sitecore powershell local deploy develop devops install iis solr

.LICENSEURI https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal/blob/main/LICENSE

.PROJECTURI https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.SYNOPSIS
PowerShell Module for Local Sitecore deployment/development

.DESCRIPTION
PowerShell Module for installing Local Sitecore deployment/development - Install-SitecoreLocal, Start-SitecoreLocal, Stop-SitecoreLocal

.EXAMPLE
PS> .\Remove-SitecoreLocal 'name'

.EXAMPLE
PS> .\Remove-SitecoreLocal 'name' '9.3.0'

.EXAMPLE
PS> .\Remove-SitecoreLocal 'name' '9.3.0' 'd:\repos'

.EXAMPLE
PS> .\Remove-SitecoreLocal 'name' '9.3.0' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Remove-SitecoreLocal
#####################################################
#[alias("un-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Remove-SitecoreLocal {
	[CmdletBinding(SupportsShouldProcess)]
    Param (
		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFile = "",

		# Name of Sitecore Local instance [dfault prefix from ConfigurationFile]
		[Parameter(Mandatory=$false)] [string]$name = ''

	)
	begin {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		$ErrorActionPreference = 'Stop'
		$VerbosePreference = 'SilentlyContinue'
		
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
		Write-Host $parametersResults.output -ForegroundColor Green
		$started = $parametersResults.started

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
				#Start-Transcript $logPath
				$parametersUpdated = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show
				Write-Host $parametersUpdated.output -ForegroundColor Green
				#$parameters = $parametersUpdated.parameters


				#todo: Uninstall-SitecoreCommerce???
				#Set-Location .\xc\install
				#. .\uninstall-xcSingle -Force -ErrorAction SilentlyContinue
				
				$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
				if (!$config) {
					throw "Error trying to load configuration!"
				}
				$assets = $config.assets
				
				(Get-IISAppPool $name).Recycle()

				$results = "end"

				$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
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
		#Write-Host "#####################################################" -ForegroundColor Green
		#Write-Host "# $PSScriptName" -ForegroundColor Magenta
		#Write-Host ("# {0:yyyy-MM-dd hh:mm:ss} $PSCommandPath" -f (Get-Date)) -ForegroundColor Cyan
		#PSSenderInfo
		#Write-Host ($PSBoundParameters | Out-String).Trim() -ForegroundColor Cyan
		#Write-Host "#####################################################" -ForegroundColor Green
		
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $started
		Write-Host $parametersResults.output -ForegroundColor Green
		
		$StopWatch.Stop()
		$StopWatch

		Write-Verbose "$PSScriptName $hostname $version end"
		Pop-Location
		#Stop-Transcript
    }
}