#Set-StrictMode -Version Latest
#####################################################
# Install-SitecoreLocal
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
PS> .\Install-SitecoreLocal 'name'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' '9.3.0'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' '9.3.0' 'd:\repos'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' '9.3.0' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Install-SitecoreLocal
#####################################################
#[alias("in-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Install-SitecoreLocal {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$false)]
    Param (
		# Name of new Sitecore Local instance [default=dev]
		[Parameter(Mandatory=$false)] [string]$name = 'dev',
		# Version of new Sitecore Local instance [default=9.3.0]
		[Parameter(Mandatory=$false)] [string]$version = "9.3.0",
		#[Parameter(Mandatory=$false)] [string]$version = "10.1.0",
		# Version of new Sitecore Local instance [default=9.3.0 rev. 003498]
		[Parameter(Mandatory=$false)] [string]$sitecoreVersion = "9.3.0 rev. 003498",
		#[Parameter(Mandatory=$false)] [string]$sitecoreVersion = "10.1.0 rev. 005207",
		# hostname of new Sitecore Local instance [default=$prefix.$name.$suffix]
		[Parameter(Mandatory=$false)] [string]$hostname = '',
		# Prefix of new Sitecore Local instance [default=$version[\.].[name]]
		[Parameter(Mandatory=$false)] [string]$prefix = '$version',
		# Suffix of new Sitecore Local instance [default=local]
		[Parameter(Mandatory=$false)] [string]$suffix = 'local',
		# SqlServer of new Sitecore Local instance [default=.]
		[Parameter(Mandatory=$false)] [string]$sqlServer = '.',
		# SqlUser of new Sitecore Local instance [default=sa]
		[Parameter(Mandatory=$false)] [string]$sqlUser = 'sa',
		# SqlPwd of new Sitecore Local instance [default='']
		[Parameter(Mandatory=$false)] [alias('sqlPassword')][string]$sqlPwd = '',
		# SitecoreUser of new Sitecore Local instance [default=admin]
		[Parameter(Mandatory=$false)] [alias('SitecoreUser')][string]$scUser = "admin",
		# SitecorePassword of new Sitecore Local instance [default: '']
		[Parameter(Mandatory=$false)] [alias('SitecorePassword')][string]$scPwd = "",
		
		# LicenseFile of new Sitecore Local instance [default=$packages\license.xml]
		[Parameter(Mandatory=$false)]
		[ValidateScript({Test-Path $_ -PathType 'Leaf'})]
		[alias('license')]
		[string]$LicenseFile = "",
		
		# wwwroot - location of new Sitecore Local instance [default=d:\webs,c:\inetpub\wwwroot]
		[Parameter(Mandatory=$false)]
		#[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[alias('www')]
		[string]$wwwroot = "",
		
		# solrRoot of new Sitecore Local instance [default=\solr\solr-[version[8.1.1]]
		[Parameter(Mandatory=$false)]
		[string]$solrRoot = "",

		# solrService of new Sitecore Local instance [default=solr-[version[8.1.1]]]]
		[Parameter(Mandatory=$false)]
		[string]$solrService = "",
		
		# solrService of new Sitecore Local instance [default=8.4.0]
		[Parameter(Mandatory=$false)]
		[string]$solrVersion = "8.1.1",

		# solrUrl of new Sitecore Local instance [default=localhost]
		[Parameter(Mandatory=$false)]
		[string]$solrHost = "localhost",

		# solrUrl of new Sitecore Local instance [default=8[version[840]]]
		[Parameter(Mandatory=$false)]
		[string]$solrPort = "",
		
		# solrUrl of new Sitecore Local instance [default=https://localhost:[solrPort]/solr]
		[Parameter(Mandatory=$false)]
		[string]$solrUrl = "",
		
		# Identity Server Site Name of new Sitecore Local instance [default=$hostname-si]
		[Parameter(Mandatory=$false)]
		[alias('IdentityServerName')]
		[string]$idName = "",
		
		# xConnect Site Name of new Sitecore Local instance [default=$hostname-xconnect]
		[Parameter(Mandatory=$false)]
		[alias('xConnectSiteName')]
		[string]$xcName = "",

		# Root path to assets [default=repos\docker-images\build\packages]
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
		[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[string] $assetsRoot = "",
		
		# certificats path for certificates [default=assets\certs]
		#[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[Parameter(Mandatory=$false)]		
		[string]$certs = "",
		
		# packages path for downloaded Sitecore packages [default=\repos\docker-images\build\packages]
		[Parameter(Mandatory=$false)]
		[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[string]$packages = "",
		
		# LogFolder path for logs [default=.\logs]
		[Parameter(Mandatory=$false)]
		#[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[alias('logs')]
		[string]$LogFolder = "",
		
		# Configuration file name [default=[ConfigurationRoot]\[ConfigurationFileName]]
		[Parameter(Mandatory=$false)]
		[ValidateScript({Test-Path $_ -PathType 'Leaf'})]
		[string]$ConfigurationFile = "",
		
		# Configuration file name [default=[hostname].json]
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFileName = "",
		
		# Configuration file name [default=\assets\[version[.\]\[ConfigurationTemplate]]
		[Parameter(Mandatory=$false)]
		[ValidateScript({Test-Path $_ -PathType 'Container'})]
		[string]$ConfigurationRoot = "",

		# Configuration file name [default=XP0]
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationTemplate = "XP0",
		
		# Configuration file name [default='Install-SitecoreLocal.json']
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationTemplateFile = "",
		
		# XConnectPackage path for logs [default=.\logs]
		[Parameter(Mandatory=$false)]
		[alias('XConnectPackage')]
		[string]$xcPkg = '',
			
		# SitecorePackage path for logs [default=.\logs]
		[Parameter(Mandatory=$false)]
		[alias('SitecorePackage')]
		[string]$scPkg = '',
		
		# SitecorePackage path for logs [default=.\logs] # The path to the Identity Server Package to Deploy.
		[Parameter(Mandatory=$false)]
		[alias('IdentityServerPackage')]
		[string]$idPkg = '',

		# PasswordRecoveryUrl path for logs [default=https://hostname]
		[Parameter(Mandatory=$false)]
		[string]$RecoveryUrl = "",
		
		# SitecoreIdentityAuthority path for logs [default=https://hostname-si]
		[Parameter(Mandatory=$false)]
		[string]$SitecoreIdentityAuthority = '',
		
		# XConnectCollectionService path for logs [default=https://hostname-si]
		[Parameter(Mandatory=$false)]
		[string]$XConnectCollectionService = '',

		# ClientSecret for Sitecore instance [default=SIF-Default]
		[Parameter(Mandatory=$false)]
		$ClientSecret = "SIF-Default",
		
		# Persist these settings - None, User, Machine Process [default=None]
		[Parameter(Mandatory=$false)]
		[ValidateSet('None','Machine','Process','User')]
		[string]$Persist = 'None',
		
		# path to assets.json to be installed [default=ConfigurationRoot\assets.json]
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
		[ValidateScript({Test-Path $_ -PathType 'Leaf'})]
		[string] $assetsJsonPath = "",

		# Force - overwrite if exists
		[Parameter(Mandatory=$false)] [switch]$Force = $false
    )
	begin {
		$ErrorActionPreference = 'Stop'
		$VerbosePreference = 'SilentlyContinue'
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
		Write-Host $parametersResults.output -ForegroundColor Green
		$started = $parametersResults.started
		
		$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
		$StopWatch.Start()

		$PSScriptPath = Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name
		$PSScriptFolder = Split-Path $PSScriptPath -Parent
		$PSRootDrive = if (Get-PSDrive 'd' -ErrorAction SilentlyContinue) { 'd:' } else { 'c:' }

		$PSReposPath = Join-Path $PSRootDrive "repos"
		if(!(Test-Path $PSReposPath)){New-Item -Path $PSReposPath -ItemType Directory}

		$PSRepoPath = Split-Path $PSScriptFolder -Parent
		if ($PSRepoPath.IndexOf('src') -ne -1) {
			$PSRepoPath = Split-Path (Split-Path $PSRepoPath -Parent) -Parent
		} else {
			$PSRepoPath = Join-Path $PSReposPath "SitecoreLocal"
		}

		if($prefix -eq '$version'){ $prefix = ($version.Replace(".", "")) }
		#$prefix += ".$name"
		$suffix = "$name.$suffix"
		if(!$hostname){ $hostname = "$prefix.$suffix" }

		if(!$LogFolder){ $LogFolder = Join-Path $PSRepoPath "logs" }
		if(!(Test-Path $logFolder)){ New-Item -Path $logFolder -ItemType Directory}
		$dateFormat = Get-Date -Format "yyyy-MM-dd"
	`	$logPath = Join-Path $LogFolder "$hostname-$dateFormat.log"
		if (Test-Path $logPath) {
			$logPathNew = "$hostname-{0:yyyy-MM-dd-hh-mm}.log" -f ((Get-Date (Get-Item $logPath).CreationTime))
			if (Test-Path $logPathNew) {
				$logPathNew = "$hostname-{0:yyyy-MM-dd-hh-mm-ss}.log" -f ((Get-Date (Get-Item $logPath).CreationTime))
			}
			Write-Verbose "Renaming $logPath to $logPathNew"
			Rename-Item -Path $logPath -NewName $logPathNew -Force
		}
		
		#ie.. module/script version number in path?

		if([string]::IsNullOrEmpty($packages)) {
			if(!(Test-Path $PSReposPath)){New-Item -Path $PSReposPath -ItemType Directory}
			$dockerImagesPath = Join-Path $PSReposPath "docker-images"
			if(!(Test-Path $dockerImagesPath)){New-Item -Path $dockerImagesPath -ItemType Directory}
			$dockerImagesBuildPath = Join-Path $dockerImagesPath "build"
			if(!(Test-Path $dockerImagesBuildPath)){New-Item -Path $dockerImagesPath -ItemType Directory}
			$packagesPath = Join-Path $dockerImagesBuildPath "packages"
			if(!(Test-Path $packagesPath)){New-Item -Path $packagesPath -ItemType Directory}
			$packages = $packagesPath
		}
		if([string]::IsNullOrEmpty($assetsRoot)) {$assetsRoot = Join-Path $PSRepoPath 'assets'}		
		if([string]::IsNullOrEmpty($ConfigurationRoot)) { $ConfigurationRoot = Join-Path $assetsRoot "configs\$version\$ConfigurationTemplate" }
		if([string]::IsNullOrEmpty($ConfigurationFileName)) { $ConfigurationFileName = "$hostname.json" }
		if([string]::IsNullOrEmpty($ConfigurationTemplateFile)) { $ConfigurationTemplateFile = "$PSScriptPath.json"}
		if([string]::IsNullOrEmpty($certs)) { $certs = Join-Path $assetsRoot "certs" }		
		if(!(Test-Path $certs)){ New-Item -Path $certs -ItemType Directory}
		if([string]::IsNullOrEmpty($assetsJsonPath)) { $assetsJsonPath = Join-Path $ConfigurationRoot 'assets-basic.json' }
		
		if(!$LicenseFile) {	$LicenseFile = "$packages\license.xml" }
		if(!$RecoveryUrl){ $RecoveryUrl = "https://$hostname" }
		if(!$idName){ $idName = "$prefix-id.$suffix" }
		if(!$SitecoreIdentityAuthority){ $SitecoreIdentityAuthority = "https://$idName" }		
		if(!$xcName){ $xcName = "$prefix-xc.$suffix" }
		if(!$XConnectCollectionService){ $XConnectCollectionService = "https://$xcName" }
		if(!$solrService) { $solrService = "Solr-$solrVersion" }
		if(!$solrRoot) { $solrRoot = Join-Path $PSRootDrive "\tools\solr\$solrService" }
		if(!$solrPort) { $solrPort = "8" + $solrVersion.Replace(".", "") }
		if(!$solrUrl) { $solrUrl = "https://$($solrHost):$solrPort/solr" }
		if(!$wwwroot) {
			write-Verbose 'wwwroot not provided.'
			if ($PSRootDrive -eq 'c:') {
				$wwwroot = Join-Path $PSRootDrive 'inetpub\wwwroot'
			} else {
				$wwwroot = Join-Path $PSRootDrive 'webs'
				if (!(Test-Path $wwwroot)) {
					$wwwroot = Join-Path $PSRootDrive 'inetpub\wwwroot'
				}
			}
		}
	}
	process {
		try {
			if($PSCmdlet.ShouldProcess($ConfigurationRoot)) {
				Start-Transcript $logPath
				$parametersUpdated = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show
				Write-Host $parametersUpdated.output -ForegroundColor Green
				$parameters = $parametersUpdated.parameters
							
				if (!(Test-Path $wwwroot)) {
					Write-Verbose 'wwwroot not found - creating:$($wwwroot)'
					New-Item -Path $wwwroot -ItemType Directory
				}

				if (!(Test-Path $assetsRoot)) {
					mkdir $assetsRoot #| Out-Null
				}
				
				if (!$certs) { #validation means it must exist before setting
					if (!(Test-Path (Join-Path $assetsRoot "certs"))) {
						mkdir (Join-Path $assetsRoot "certs")
					}
					$certs = Join-Path $assetsRoot "certs"
				}
				
				#if (!(Test-Path $configs)) {
				#	mkdir $configs #| Out-Null
				#}
				
				if (!(Test-Path $packages)) {
					Write-Verbose "Packages not found!"
					$packages = Join-Path $assetsRoot "packages"
					if (!(Test-Path $packages)) {
						mkdir $packages #| Out-Null
					}
				}
				
				if([string]::IsNullOrEmpty($scPkg)){
					$scPkgItem = Get-ChildItem "$packages\Sitecore $version rev. * (OnPrem)_single.scwdp.zip" -ErrorAction SilentlyContinue
					if ($scPkgItem) {
						$scPkg = $scPkgItem.FullName 
					}
				}
				if(!(Test-Path $scPkgItem)) {
					Write-Error "File not found - $packages\Sitecore $version rev. * (OnPrem)_single.scwdp.zip" -ErrorAction Stop
				}

				$IdentityServerVersion = ''
				if (!$IdentityServerVersion) {
					if ($version -eq "9.3.0") {
						$IdentityServerVersion = "4.0.0 rev. 00257"
					} elseif ($version -eq "10.1.0") {
						$IdentityServerVersion = "5.1.0 rev. 00290"
					}
				}
				if (!$IdentityServerVersion) {
					Write-Error "IdentityServerVersion not determined" -ErrorAction Stop
				}
				Write-Verbose "Looking for $packages\Sitecore.IdentityServer $IdentityServerVersion (OnPrem)_identityserver.scwdp.zip"
				if([string]::IsNullOrEmpty($idPkg)){
					$idPkgItem = Get-ChildItem "$packages\Sitecore.IdentityServer $IdentityServerVersion (OnPrem)_identityserver.scwdp.zip" -ErrorAction SilentlyContinue
					if ($idPkgItem) {
						$idPkg = $idPkgItem.FullName
					}
				}
				if(!(Test-Path $idPkgItem)) {
					Write-Error "File not found - $packages\Sitecore.IdentityServer $IdentityServerVersion (OnPrem)_identityserver.scwdp.zip" -ErrorAction Stop
				}

				Write-Verbose "Looking for $packages\Sitecore $version rev. * (OnPrem)_xp0xconnect.scwdp.zip"
				if([string]::IsNullOrEmpty($xcPkg)){
					$xcPkgItem = Get-ChildItem "$packages\Sitecore $version rev. * (OnPrem)_xp0xconnect.scwdp.zip"
					if ($xcPkgItem) {
						$xcPkg = $xcPkgItem.FullName
					} else {
						Write-Error "File not found - $packages\Sitecore $version rev. * (OnPrem)_xp0xconnect.scwdp.zip" -ErrorAction Stop
					}
				}
				if(!(Test-Path $xcPkgItem)) {
					Write-Error "You must download: Sitecore $version rev. * (WDP XP0 packages).zip in: $packages" -ErrorAction Stop -ErrorAction Stop
				}
				
				$configPkgItem = Get-ChildItem -Path "$packages\XP0 Configuration files $version rev. *.zip"
				if(!$configPkgItem){
					Add-Type -Assembly System.IO.Compression.FileSystem
					$scPkgZip = [IO.Compression.ZipFile]::OpenRead($scPkg)
					[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($scPkgZip, $packages)
					$scPkgZip.Dispose()
					$configPkgItem = Get-ChildItem -Path "$packages\XP0 Configuration files $version rev. *.zip"
					Write-Verbose "ExtractToDirectory:$scPkg"
				}
				
				if(!$configPkgItem){
					Write-Error "Error extracting $scPkg" -ErrorAction Stop
				} else {
					$configPkg = $configPkgItem.FullName
				}
				
				$configTestFile = Join-Path $ConfigurationRoot "XP0-SingleDeveloper.json"
				if (!(Test-Path $configTestFile) -or $Force) {
					if ($ConfigurationRoot) {
						Write-Verbose "Expanding:$configPkg"
						#Add-Type -Assembly System.IO.Compression.FileSystem
						#$configPkgZip = [IO.Compression.ZipFile]::OpenRead($configPkg)
						#[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($configPkgZip, $ConfigurationRoot) -Force
						#$configPkgZip.Dispose()
						Expand-Archive -Path $configPkg -DestinationPath $ConfigurationRoot -Force
						Write-Verbose "ExtractToDirectory:$configPkg"
					}
				}

				$existing = ![string]::IsNullOrEmpty($ConfigurationFile)
				if (!$existing -or $Force) {
					$ConfigurationFileTest = Join-Path $ConfigurationRoot $ConfigurationFileName
					Write-Host "Creating:$ConfigurationFileTest" -ForegroundColor Cyan
					Copy-Item $ConfigurationTemplateFile $ConfigurationFileTest
					$ConfigurationFile = $ConfigurationFileTest

					Set-SitecoreLocal $ConfigurationFile $ConfigurationFileName $ConfigurationRoot $ConfigurationTemplate $assetsRoot $packages $version $hostname $prefix $suffix

					# update parameters
					Write-Host 'Updating parameters...'
					$parametersResponse = Get-Parameters $MyInvocation.MyCommand.Parameters $parameters "$PSScriptName Updating configs..."
					Write-Host $parametersResponse.output -ForegroundColor Green
					$parameters = $parametersResponse.parameters

					Write-Host 'Updating configs...'
					Set-SitecoreLocalOverrides @parameters
					Write-Host 'Updating configs...completed *******************'
				} else {
					Write-Host "Existing config:$ConfigurationFile"
				}				
				
				Write-Host "Loading config:$ConfigurationFile"
				$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
				if (!$config) {
					throw "Error trying to load configuration!"
				}
				Write-Host "Loaded config:$ConfigurationFile"

				#Set-SitecoreDockerLicense - use env like docker?
				
				if ($Force) {
					#todo: add a check?
					#Remove-SitecoreLocalDb $ConfigurationFile
					Write-Host "Running Remove-SitecoreLocalDb:$ConfigurationFile"
					Remove-SitecoreLocalDb $ConfigurationFile
				}
				

				#todo
				
				#$moduleName = 'SharedInstallationUtilities'
				#Install-ModuleFromGithub -ModuleName $moduleName -UriBase "https://raw.githubusercontent.com/Sitecore/Sitecore.HabitatHome.Utilities/master/Shared/assets/modules/SharedInstallationUtilities/SharedInstallationUtilities.psm1"
				#Import-Module -Name $moduleName
				#Install-SitecoreAzureToolkit
				
				
				#Set-Location "$reposPath\$dockerimages"



				#	Set-ExecutionPolicy Bypass -Scope Process -Force; 
				#	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
				#	iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
				#	choco install mkcert
				#	mkcert $cert
				#	Set-Location ..
				#}
				
				#pre pre-req check.. ie.. choco.. and sql

				#exit 1
			
				#Set-Location $ogp
				#Set-Location .\xp



				#Write-Verbose 'Setting/Checkings paths...'
				
				
			

				$site = $config.settings.site
				$sql = $config.settings.sql
				$xConnect = $config.settings.xConnect
				$sitecore = $config.settings.sitecore
				$identityServer = $config.settings.identityServer
				$solr = $config.settings.solr
				
				$assets = $config.assets
				
				#Write-Verbose "resourcePath:$resourcePath"
				Write-Host "assets.sharedUtilitiesRoot:$($assets.sharedUtilitiesRoot)"
				$sharedResourcePath = Join-Path $assets.sharedUtilitiesRoot "assets\configuration"
				Write-Host "sharedResourcePath:$sharedResourcePath"
	
				Write-Host 'Installing pre-reqs......'
				try {
					Import-Module (Join-Path $assets.sharedUtilitiesRoot "assets\modules\SharedInstallationUtilities\SharedInstallationUtilities.psm1") -Force
					Install-SitecoreLocalPrerequisites $solrVersion $ConfigurationFile $logFolder $sharedResourcePath
				}
				catch {
					Write-Error "ERROR:$_" -InformationVariable results
				}
				Write-Host 'Prerequisites installed.'
				Write-Verbose 'Prerequisites installed.'

				$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$hostname - $version" -Show
				Write-Host $($parametersResults.output) -ForegroundColor Green
				
				Write-Host 'Checking IIS/Starting w3svc...'
				#confirm IIS is running & may not be if playing with https://github.com/SitecoreDave/SharedSitecore.SitecoreDocker
				Start-Service w3svc

				#Install-SingleDeveloper
				Write-Host 'Install-SingleDeveloper $($sitecore.singleDeveloperConfigurationPath): started'
				#IdentityServerName = $idName
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
				
				Write-Host "ConfigurationRoot:$ConfigurationRoot" -ForegroundColor Green
				Push-Location $ConfigurationRoot #(Join-Path $resourcePath "XP0")
				
				Install-SitecoreConfiguration @singleDeveloperParams
				#Install-SingleDeveloper $ConfigurationFile
			
				#currently fails and then breaks site: login failed for: securityuser
				#Install-SitecoreLocalModules $ConfigurationFile -Verbose

				Pop-Location
						
				#CONFIGURE/FINISH
				Add-AppPoolMembership
				Add-AdditionalBindings
				Edit-CryptographyAlgorithmsBindingRedirect
				
				Write-Host "# $PSScriptName ended successfully" -InformationVariable results -ForegroundColor Magenta
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

# SIG # Begin signature block
# MIIFwQYJKoZIhvcNAQcCoIIFsjCCBa4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUb+LpGlo/td0TqaWD91fdBl6j
# scagggNOMIIDSjCCAjKgAwIBAgIQHpPHVhJV5LBKSHdfHA+9HzANBgkqhkiG9w0B
# AQsFADAoMSYwJAYDVQQDDB1TaGFyZWRTaXRlY29yZS5TaXRlY29yZURvY2tlcjAe
# Fw0yMTAxMjcyMTUxMDJaFw0yMjAxMjcyMjExMDJaMCgxJjAkBgNVBAMMHVNoYXJl
# ZFNpdGVjb3JlLlNpdGVjb3JlRG9ja2VyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA0v29oDKrlTF1LgojLFLlqC/jP5LbQ46oGDJGi+D94HTLCcSGpOk9
# HcE5x1aedVMK65CBHFj5BjY8j5NEVDi67fpif3OGmVWagjwclJzylcKlQgTioV6+
# rfffuJtFQ0/C3ftXy+l083ophmRPN8bu6BMWkC1uaHIg2Qqd7cf6Keu5j3LGw2eJ
# ncoSyZtxNSjbfX6FHm2KR0y9kD3RmBAUDZEmulht2mvn2ezGgPvJgCaMrW7xXq13
# iCx+TFdeaLLD5+V49WtWsW1PiHRFV7VMkOfjHOgW1mAYhlTCL38ByyqEG6D2dVGy
# ATX05fYszuRLfPdelxotvrk78evLiTaYeQIDAQABo3AwbjAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwKAYDVR0RBCEwH4IdU2hhcmVkU2l0ZWNv
# cmUuU2l0ZWNvcmVEb2NrZXIwHQYDVR0OBBYEFKT93awe2JYz+yfWHfrRE0AgR6Jg
# MA0GCSqGSIb3DQEBCwUAA4IBAQBYCsL16TX6A+72bbWp6IhGIh2SPwPlHJKEhAmX
# KK+TGe27yWEqLD2eEAgIHFd4IEFg3Fm+4ybJsAAbVh1+kePtELlrct+7brMaDvN6
# dpwPnh7K3H022C4IekCU5/DyEMZvmGtaQfAOQ9jiQC9aoseYDXg+O6Vs2HbdhL5S
# c3K8x/8jm7bLWymyFs6xatO8QzkwfWs2f/4KEzL0dW9iRmKW4HMoItIBSbe2WNKT
# TJ2VxIS3Fi+XuQDmkLngeUF5cyDXz9gnhsyImUTjV64tA1EAv0n991XC50fQRPbt
# Uybn44qecqGHObWoGYBL6Y0fdMi+PsUR3OympqCPJVPBfTINMYIB3TCCAdkCAQEw
# PDAoMSYwJAYDVQQDDB1TaGFyZWRTaXRlY29yZS5TaXRlY29yZURvY2tlcgIQHpPH
# VhJV5LBKSHdfHA+9HzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUSu5XbV9PMvdaiHxowmc3MOtP
# umMwDQYJKoZIhvcNAQEBBQAEggEABkzxl30j4k/IOC+AN1BNvDkP942Q603Pky7E
# h1AYXpqQx53wYbab83obvXIVifeAfJxASh1Wt/JaTKpnJ6Ged6t4457jLQ96rbtm
# Wrcvem2vbBMkbFRMbYptPnilEAtzPCRtqwm6B72ERDS5LQih/796ojskOqh4OLPd
# fWSrSsCLIPioiAYhnBiCGVr/4kuaYu4z2fYXtznJcHfqL9bl6nG47RPPDO2xmBuE
# u3a5frvDiLs4N92/eqZH1bUqNxRAv5Z4nREW7RqFY7v73lQhzHggDWYtk8ChADea
# TGBVcn0rQCGOz/oXBRqCBk9MSz35NH7AIKgHk+ekQPEbGjz2PQ==
# SIG # End signature block
