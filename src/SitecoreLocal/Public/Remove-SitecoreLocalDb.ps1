#Set-StrictMode -Version Latest
#####################################################
# Remove-SitecoreLocalDb
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
PS> .\Remove-SitecoreLocalDb 'name'

.EXAMPLE
PS> .\Remove-SitecoreLocalDb 'name' '9.3.0'

.EXAMPLE
PS> .\Remove-SitecoreLocalDb 'name' '9.3.0' 'd:\repos'

.EXAMPLE
PS> .\Remove-SitecoreLocalDb 'name' '9.3.0' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Remove-SitecoreLocalDb
#####################################################
#[alias("un-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Remove-SitecoreLocalDb {
	[CmdletBinding(SupportsShouldProcess)]
    Param (
		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFile = "",
		[Parameter(Mandatory=$false)]
		[string]$prefix = ""
	)
	begin {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12		
		$ErrorActionPreference = 'Stop'
		$VerbosePreference = 'SilentlyContinue'
		
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
		Write-Host $parametersResults.output -ForegroundColor Green
		$started = $parametersResults.started

		if ($ConfigurationFile -like '.\*') {
			$ConfigurationFile = Join-Path $PSScriptRoot $ConfigurationFile.Remove(0,2);
		}

		if ((Test-Path "$($ConfigurationFile).user")) {
			$ConfigurationFile = "$($ConfigurationFile).user"
		}
		if (!(Test-Path $ConfigurationFile)) {
			Write-Host 'Configuration file '$($ConfigurationFile)' not found.' -ForegroundColor Red
			Write-Host  'Please use 'set-installation...ps1' files to generate a configuration file.' -ForegroundColor Red
			Exit 1
		}
	}
	process {
		try {
			if($PSCmdlet.ShouldProcess($ConfigurationFile)) {
				#Start-Transcript $logPath
				$parametersUpdated = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show
				Write-Host $parametersUpdated.output -ForegroundColor Green
				#$parameters = $parametersUpdated.parameters
				
				$config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
				if (!$config) {
					throw "Error trying to load configuration!"
				}
				
				$settings = $config.settings
				$site = $settings.site
				$sql = $settings.sql

				if (!$prefix) {$prefix = $site.prefix}
				$sqlServer = $sql.server
				$sqlAdminUser = $sql.adminUser
				$sqlAdminPassword = $sql.adminPassword

				Write-Host "prefix: $($prefix)"
				Write-Host "sqlServer: $($sqlServer)"
				Write-Host "sqlAdminUser: $($sqlAdminUser)"
				Write-Host "sqlAdminPassword: $($sqlAdminPassword)"

				#import-module sqlps

				Write-Host "Checking for databases: $($prefix)"

				$database = "master"
				$databases = Invoke-Sqlcmd -ServerInstance $sqlServer -Database $database -U $sqlAdminUser -P $sqlAdminPassword `
					-Query "SELECT NAME FROM sys.databases WHERE NAME LIKE '$($prefix)%'"

				if ($databases) {
					Write-Host "Databases found: $($databases.length)"

					$sqlQuery = ''
					foreach ($database in $databases) #for each separate server / database pair in $databases
					{
						#Write-Host $("Dropping database $($database.NAME)")
						#$sqlQuery = "DROP DATABASE IF EXISTS [$($database.NAME)];$sqlQuery"
						$sqlQuery = "IF EXISTS (SELECT name from sys.databases WHERE name='$($database.NAME)') BEGIN ALTER DATABASE [$($database.NAME)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;DROP DATABASE [$($database.NAME)];END;$sqlQuery"
						#$sqlQuery = $("IF DB_ID('$($database.NAME)') IS NOT NULL ALTER DATABASE [$($database.NAME)] SET OFFLINE WITH ROLLBACK IMMEDIATE;DROP DATABASE [$($database.NAME)]")
						#Write-Output $("Query: $($sqlQuery)")
						#Invoke-Sqlcmd -ServerInstance $SqlServer -U $sqlAdminUser -P $sqlAdminPassword -Query $sqlQuery -ErrorAction SilentlyContinue
					}
					if ($sqlQuery) {
						Write-Output $("Query: $($sqlQuery)")
						$databases = Invoke-Sqlcmd -ServerInstance $sqlServer -U $sqlAdminUser -P $sqlAdminPassword -Query $sqlQuery
					}
				}
				else {
					Write-Host 'No databases found.'
				}
				Write-Host "completed"

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