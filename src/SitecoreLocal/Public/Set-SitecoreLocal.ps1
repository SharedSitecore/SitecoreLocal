#Set-StrictMode -Version Latest
#####################################################
# Set-SitecoreLocal
#####################################################
<#PSScriptInfo

.VERSION 0.0

.GUID 602bc07e-a621-4738-8c27-0edf4a4cea8e

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS sitecore powershell local install iis solr

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
@@synoposis@@

.DESCRIPTION
@@description@@

.EXAMPLE
PS> .\Set-SitecoreLocal 'name'

.EXAMPLE
PS> .\Set-SitecoreLocal 'name' 'template'

.EXAMPLE
PS> .\Set-SitecoreLocal 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Set-SitecoreLocal 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Set-SitecoreLocal
#####################################################
#[alias("in-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Set-SitecoreLocal
{
    [CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(        
        # Configuration file name [default=[ConfigurationRoot]\[ConfigurationFileName]]
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$ConfigurationFile = "",
        
        # Configuration file name [default=[hostname]].json]
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationFileName = "",
        
        # Configuration file name [default=\assets\[version[.\]\[ConfigurationTemplate]]
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$ConfigurationRoot = "",

        # Configuration file name [default=XP0]
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationTemplate = "XP0",

        [string] $assetsRoot,
        [string] $packageRepository,
        [string] $version = "9.3.0",
        #[string] $version = "10.1.0",

        # hostname of new Sitecore Local instance [default=$prefix+$suffix]
		[Parameter(Mandatory=$false)] [string]$hostname = '',

        # name of new Sitecore Local instance [default=dev]
		[Parameter(Mandatory=$false)] [string]$name = '',

		# Prefix of new Sitecore Local instance [default=$version[\.].[name]]
		[Parameter(Mandatory=$false)] [string]$prefix = '$version',

		# Suffix of new Sitecore Local instance [default=.local]
		[Parameter(Mandatory=$false)] [string]$suffix = '.local'
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Host (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):started" -Show -Stamp).output
    
    if ([string]::IsNullOrEmpty($assetsRoot)) {
        $assetsRoot = Join-Path $PSScriptRoot "assets"
        $srcIndex = $PSScriptRoot.IndexOf("src")
        if ($srcIndex -ne -1) {
            $PSRepoRoot = $PSScriptRoot.Substring(0, $srcIndex)
            $assetsRoot = Join-Path $PSRepoRoot "assets"
        }
    }
    Write-Host "Using assetsRoot:$assetsRoot"
    
    if ($prefix -eq '$version'){ $prefix = ($version.Replace(".", "") + ".$name") }
    if ([string]::IsNullOrEmpty($hostname)) { $hostname = "$prefix$suffix" }

    if (!$ConfigurationRoot) { $ConfigurationRoot = Join-Path $assetsRoot "configs\$version\$ConfigurationTemplate" }
    if (!$ConfigurationFile) { $ConfigurationFile = Join-Path $ConfigurationRoot "$hostname.json" }

    Write-Host "Setting Defaults and creating $ConfigurationFile"

    #Write-Host "myInvocation.InvocationName:$($myInvocation.InvocationName)"
  #  Write-Host "myInvocation.Path:$($myInvocation.Path)"
    #Write-Host "myInvocation.ScriptName:$($myInvocation.ScriptName)"

    #Write-Host "myInvocation.MyCommand.Name:$($myInvocation.MyCommand.Name)"
    #Write-Host "myInvocation.MyCommand.Definition:$($myInvocation.MyCommand.Definition)"
    #Write-Host "PSScriptRoot:$PSScriptRoot"

    $baseConfig = Join-Path $PSScriptRoot Install-SitecoreLocal.json
    if (!(Test-Path $baseConfig)) {
        Write-Error "Base config not found:$baseConfig"
        Exit 1
    }
    Write-Host "Using baseConfig:$baseConfig"
    $json = Get-Content -Raw ($baseConfig) -Encoding Ascii | ConvertFrom-Json

    #$parametersUser = Get-Content -Raw "..\local.parameters.json.user" -ErrorAction SilentlyContinue |  ConvertFrom-Json

    #$version = $sitecoreversion.Substring(0, $sitecoreVersion.IndexOf(" ") - 1).Replace(".", "")
    #$version = "9.3.0"
    #$version = "10.1.0"

    Write-Host "Setting default 'Assets and prerequisites' parameters"

    $assets = $json.assets
    if (![string]::IsNullOrEmpty($assetsRoot) -and $assets.root -ne $assetsRoot) { $assets.root = $assetsRoot }
    Write-Host "Setting assets.root:$($assets.root)"

    $assets.configurationRoot = Join-Path $assets.root "configs\$version\$ConfigurationTemplate"
    Write-Host "Setting assets.configurationRoot:$($assets.configurationRoot)"

    $assets.sitecoreVersion = "9.3.0 rev. 003498"
    #$assets.sitecoreVersion = "10.1.0 rev. 005207"

    if (![string]::IsNullOrEmpty($packageRepository)){
        $assets.packageRepository = $packageRepository
    }
    else {
        $assets.packageRepository = Join-Path $assets.root "packages"
        if (Test-Path (Join-Path (Split-Path $assets.root -Parent) 'docker-images\build\packages')){
            $assets.packageRepository = Join-Path '\' 'repos\docker-images\build\packages'
        }
    }
    Write-Host "Setting assets.packageRepository:$($assets.packageRepository)"

	$assets.psRepository = "https://sitecore.myget.org/F/sc-powershell/api/v2/"
	$assets.psRepositoryName = "SitecoreGallery"
	$assets.installerVersion = "2.3.0"
	#$assets.sharedUtilitiesRoot = (Resolve-Path "..\..\Shared" | Select-Object -ExpandProperty Path)
	$assets.sharedUtilitiesRoot = Join-Path $assets.root "Shared"
	$assets.sitecoreazuretoolkit = Join-Path $assets.sharedUtilitiesRoot "sat"

	$assets.licenseFilePath = Join-Path $assets.packageRepository "license.xml"

    $assets.identityServerVersion = "4.0.0 rev. 00257"
    #$assets.identityServerVersion = "5.1.0 rev. 00290"


    $assets.certificatesPath = Join-Path $assets.root "certs"

    Write-Host "Setting assets.sharedUtilitiesRoot:$($assets.sharedUtilitiesRoot)"

    # Settings
    Write-Host "Setting default 'Site' parameters"
    # Site Settings
    $site = $json.settings.site
	$site.prefix = $version.Replace(".", "") + ".dev" #default name
    $site.suffix = ".local"
    $site.webroot = "C:\inetpub\wwwroot"
    $site.hostName = $json.settings.site.prefix + $json.settings.site.suffix
    $site.addSiteBindingWithSSLPath = (Get-ChildItem $assets.sharedUtilitiesRoot -filter "add-new-binding-and-certificate.json" -Recurse).FullName

    $basePwd = "$((Get-ComputerDescription).Replace(' ',''))"
    Write-Host "basePwd:$($basePwd)"
    Write-Host "Setting default 'SQL' parameters"
    $sql = $json.settings.sql
    # SQL Settings
    $SqlSaPassword = "$($basePwd)Rocks!"
    $SqlStrongPassword = $SqlSaPassword # Used for all other services
    
    $sql.server = "."
    $sql.adminUser = "sa"
    $sql.adminPassword = $SqlSaPassword
    $sql.userPassword = $SqlStrongPassword
    $sql.coreUser = "coreuser"
    $sql.corePassword = $SqlStrongPassword
    $sql.masterUser = "masteruser"
    $sql.masterPassword = $SqlStrongPassword
    $sql.webUser = "webuser"
    $sql.webPassword = $SqlStrongPassword
    $sql.collectionUser = "collectionuser"
    $sql.collectionPassword = $SqlStrongPassword
    $sql.reportingUser = "reportinguser"
    $sql.reportingPassword = $SqlStrongPassword
    $sql.processingPoolsUser = "poolsuser"
    $sql.processingPoolsPassword = $SqlStrongPassword
    $sql.processingEngineUser = "processingengineuser"
    $sql.processingEnginePassword = $SqlStrongPassword
    $sql.processingTasksUser = "tasksuser"
    $sql.processingTasksPassword = $SqlStrongPassword
    $sql.referenceDataUser = "referencedatauser"
    $sql.referenceDataPassword = $SqlStrongPassword
    $sql.marketingAutomationUser = "marketingautomationuser"
    $sql.marketingAutomationPassword = $SqlStrongPassword
    $sql.formsUser = "formsuser"
    $sql.formsPassword = $SqlStrongPassword
    $sql.exmMasterUser = "exmmasteruser"
    $sql.exmMasterPassword = $SqlStrongPassword
    $sql.messagingUser = "messaginguser"
    $sql.messagingPassword = $SqlStrongPassword
    $sql.securityuser = "securityuser"
    $sql.minimumVersion = "13.0.4001"

    Write-Host "Setting default 'xConnect' parameters"
	# XConnect Parameters
    $xConnect = $json.settings.xConnect
    $xConnect.ConfigurationPath = (Get-ChildItem $assets.configurationRoot -filter "xconnect-xp0.json" -Recurse).FullName
    $xConnect.certificateConfigurationPath = (Get-ChildItem $assets.configurationRoot -filter "createcert.json" -Recurse).FullName
    $xConnect.solrConfigurationPath = (Get-ChildItem $assets.configurationRoot -filter "xconnect-solr.json" -Recurse).FullName
    $xConnect.packagePath = Join-Path $assets.packageRepository $("Sitecore " + $assets.sitecoreVersion + " (OnPrem)_xp0xconnect.scwdp.zip")
    $xConnect.siteName = $site.prefix + "-xconnect"
    $xConnect.siteRoot = Join-Path $site.webRoot -ChildPath $xConnect.siteName

    Write-Host "Setting default 'Sitecore' parameters"
    # Sitecore Parameters
    $sitecore = $json.settings.sitecore
    $sitecore.solrConfigurationPath = (Get-ChildItem $assets.configurationRoot -filter "sitecore-solr.json" -Recurse).FullName
    $sitecore.singleDeveloperConfigurationPath = (Get-ChildItem $assets.configurationRoot -filter "XP0-SingleDeveloper.json" -Recurse).FullName
    $sitecore.sslConfigurationPath = "$($assets.configurationRoot)\certificates\sitecore-ssl.json"
    $sitecore.packagePath = Join-Path $assets.packageRepository $("Sitecore " + $assets.sitecoreVersion + " (OnPrem)_single.scwdp.zip")
    $sitecore.adminPassword = "b"
    $sitecore.exmCryptographicKey = "0x0000000000000000000000000000000000000000000000000000000000000000"
    $sitecore.exmAuthenticationKey = "0x0000000000000000000000000000000000000000000000000000000000000000"
    $sitecore.telerikEncryptionKey = "PutYourCustomEncryptionKeyHereFrom32To256CharactersLong"
    $sitecore.rootCertificateName = $site.hostName #"SitecoreRoot91"
    Write-Host "Setting default 'IdentityServer' parameters"
    $identityServer = $json.settings.identityServer
    $identityServer.packagePath = Join-Path $assets.packageRepository $("Sitecore.IdentityServer " + $assets.identityServerVersion + " (OnPrem)_identityserver.scwdp.zip")
    $identityServer.configurationPath = (Get-ChildItem $assets.configurationRoot -filter "IdentityServer.json" -Recurse).FullName 
    $identityServer.name = $site.prefix + "-identityserver"
    $identityServer.url = ("https://{0}" -f $identityServer.name)
    $identityServer.clientSecret = "ClientSecret"
	
    Write-Host "Setting default 'Solr' parameters"
    # Solr Parameters
    $solr = $json.settings.solr
    #$solr.url = "https://localhost:8840/solr"
    #$solr.root = "c:\solr\solr-8.4.0"
    #$solr.serviceName = "Solr-8.4.0"

    Write-Verbose "Saving: $json"
    Set-Content $ConfigurationFile (ConvertTo-Json -InputObject $json -Depth 6 )
	Write-Host ("Saved:{0}" -f $ConfigurationFile) -InformationVariable results -ForegroundColor Green
	
	Write-Host (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}