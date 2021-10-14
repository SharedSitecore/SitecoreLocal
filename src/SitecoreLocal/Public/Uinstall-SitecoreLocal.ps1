#Set-StrictMode -Version Latest
#####################################################
# Uninstall-SitecoreLocal
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
PS> .\Uninstall-SitecoreLocal 'name'

.EXAMPLE
PS> .\Uninstall-SitecoreLocal 'name' '9.3.0'

.EXAMPLE
PS> .\Uninstall-SitecoreLocal 'name' '9.3.0' 'd:\repos'

.EXAMPLE
PS> .\Uninstall-SitecoreLocal 'name' '9.3.0' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Uninstall-SitecoreLocal
#####################################################
#[alias("un-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Uninstall-SitecoreLocal {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$false)]
    Param (
		# Name of new Sitecore Local instance [default=dev]
		[Parameter(Mandatory=$false)] [string]$name = 'dev',	

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFile = ""
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
				Start-Transcript $logPath
				$parametersUpdated = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show
				Write-Host $parametersUpdated.output -ForegroundColor Green
				#$parameters = $parametersUpdated.parameters

				$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
				if (!$config) {
					throw "Error trying to load configuration!"
				}
				
				$site = $config.settings.site
				$sql = $config.settings.sql
				$xConnect = $config.settings.xConnect
				$sitecore = $config.settings.sitecore
				$identityServer = $config.settings.identityServer
				$solr = $config.settings.solr
				
				$assets = $config.assets				

				$singleDeveloperParams = @{
					Path                           = $sitecore.singleDeveloperConfigurationPath
					SqlServer                      = $sql.server
					SqlAdminUser                   = $sql.adminUser
					SqlAdminPassword               = $sql.adminPassword
					SqlCollectionPassword          = $sql.collectionPassword
					SqlReferenceDataPassword       = $sql.referenceDataPassword
					SqlMarketingAutomationPassword = $sql.marketingAutomationPassword
					SqlMessagingPassword           = $sql.messagingPassword
					SqlProcessingEnginePassword    = $sql.processingEnginePassword
					SqlReportingPassword           = $sql.reportingPassword
					SqlCorePassword                = $sql.corePassword
					SqlSecurityPassword            = $sql.securityPassword
					SqlMasterPassword              = $sql.masterPassword
					SqlWebPassword                 = $sql.webPassword
					SqlProcessingTasksPassword     = $sql.processingTasksPassword
					SqlFormsPassword               = $sql.formsPassword
					SqlExmMasterPassword           = $sql.exmMasterPassword
					SitecoreAdminPassword          = $sitecore.adminPassword
					SolrUrl                        = $solr.url
					SolrRoot                       = $solr.root
					SolrService                    = $solr.serviceName
					Prefix                         = $site.prefix
					XConnectCertificateName        = $xconnect.siteName
					IdentityServerCertificateName  = $identityServer.name
					IdentityServerSiteName         = $identityServer.name
					LicenseFile                    = $assets.licenseFilePath
					XConnectPackage                = $xConnect.packagePath
					SitecorePackage                = $sitecore.packagePath
					IdentityServerPackage          = $identityServer.packagePath
					XConnectSiteName               = $xConnect.siteName
					SitecoreSitename               = $site.hostName
					PasswordRecoveryUrl            = "https://" + $site.hostName
					SitecoreIdentityAuthority      = "https://" + $identityServer.name
					XConnectCollectionService      = "https://" + $xConnect.siteName
					ClientSecret                   = $identityServer.clientSecret
					AllowedCorsOrigins             = ("https://{0}" -f $site.hostName)
					SitePhysicalRoot               = $site.webRoot
				}

				Uninstall-SitecoreConfiguration @singleDeveloperParams
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
		Stop-Transcript
    }
}