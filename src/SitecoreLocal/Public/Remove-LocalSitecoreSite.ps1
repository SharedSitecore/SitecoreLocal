#Set-StrictMode -Version Latest
#####################################################
# Remove-SitecoreLocalSite
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
PS> .\Remove-SitecoreLocalSite 'name'

.EXAMPLE
PS> .\Remove-SitecoreLocalSite 'name' '9.3.0'

.EXAMPLE
PS> .\Remove-SitecoreLocalSite 'name' '9.3.0' 'd:\repos'

.EXAMPLE
PS> .\Remove-SitecoreLocalSite 'name' '9.3.0' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Remove-SitecoreLocalSite
#####################################################
#[alias("un-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Remove-SitecoreLocalSite {
	[CmdletBinding(SupportsShouldProcess)]
    Param (
		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFile = "",

		# Name of new Sitecore Local instance [default=dev]exit
		[Parameter(Mandatory=$false)] [string]$name = 'dev'
	)
	begin {
		$ErrorActionPreference = 'Stop'
		$VerbosePreference = 'SilentlyContinue'
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
		Write-Host $parametersResults.output -ForegroundColor Green
		$started = $parametersResults.started
	}
	process {
		try {
			if($PSCmdlet.ShouldProcess($ConfigurationFile)) {
				#Start-Transcript $logPath
				$parametersUpdated = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show
				Write-Host $parametersUpdated.output -ForegroundColor Green
				#$parameters = $parametersUpdated.parameters

				$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
				if (!$config) {
					throw "Error trying to load configuration!"
				}
								
				$site = $config.settings.site
				#$sql = $config.settings.sql

				push-location
				#import-module sqlps

				Write-Host "Remove IIS Sites: $(($site.prefix))"
				$iisSites = Get-IISSite | Where-Object { $_.name -like "$($site.prefix)*" }

				foreach ($iisSite in $iisSites) #for each separate server / database pair in $databases
				{
					Write-Host $("Removing site $($iisSite)")
					Remove-Website $iisSite	 -ErrorAction SilentlyContinue
				}

				Write-Host "Remove IIS AppPools: $(($site.prefix))"
				$appPools = Get-IISAppPool | Select-Object Name | where-object {$_.Name -Like "$($site.prefix)*"}
				foreach($appPool in $appPools) {
					Write-Host $("Removing AppPool: $($appPool.Name)")
					try {
					Remove-WebAppPool $appPool.Name -ErrorAction SilentlyContinue
					} catch {}
				}

				Write-Host "IIS uninstalled successfully"
				pop-location



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