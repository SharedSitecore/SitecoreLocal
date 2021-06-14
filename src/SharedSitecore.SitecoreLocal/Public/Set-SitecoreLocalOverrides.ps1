#Set-StrictMode -Version Latest
#####################################################
# Set-SitecoreLocalOverrides
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
PS> .\Set-SitecoreLocalOverrides 'name'

.EXAMPLE
PS> .\Set-SitecoreLocalOverrides 'name' 'template'

.EXAMPLE
PS> .\Set-SitecoreLocalOverrides 'name' 'template' 'd:\repos'

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Set-SitecoreLocalOverrides
#####################################################
#[alias("in-sc-local")]
#Set-PSBreakpoint -Variable Now -Mode Read -Action {Set-Variable Now (get-date -uformat '%Y\%m\%d %H:%M:%S') -Option ReadOnly, AllScope -Scope Global -Force -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
function Set-SitecoreLocalOverrides
{
    [CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        # Name of new Sitecore Local instance [default=dev]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$name = 'dev',	
        # Version of new Sitecore Local instance [default=9.3.0]
        #[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$version = "9.3.0",
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$version = "10.1.0",
        # Version of new Sitecore Local instance [default=9.3.0 rev. 003498]
        #[Parameter(Mandatory=$false)] [string]$sitecoreVersion = "9.3.0 rev. 003498",    
        [Parameter(Mandatory=$false)] [string]$sitecoreVersion = "10.1.0 rev. 005207",    
        # hostname of new Sitecore Local instance [default=$prefix[version[.\].$name$suffix]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$hostname = '',
        # Prefix of new Sitecore Local instance [default=$version[\.].]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$prefix = '',
        # Suffix of new Sitecore Local instance [default=.local]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$suffix = '.local',
        # SqlServer of new Sitecore Local instance [default=.]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$sqlServer = '.',
        # SqlUser of new Sitecore Local instance [default=sa]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [string]$sqlUser = 'sa',
        # SqlPwd of new Sitecore Local instance [default='']
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [alias('sqlPassword')][string]$sqlPwd = '',
        # SitecoreUser of new Sitecore Local instance [default=admin]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [alias('SitecoreUser')][string]$scUser = "admin",
        # SitecorePassword of new Sitecore Local instance [default: '']
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)] [alias('SitecorePassword')][string]$scPwd = "",
        
        # LicenseFile of new Sitecore Local instance [default=$assets\\license\\license.xml]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [alias('license')]
        [string]$LicenseFile = "",
        
        # wwwroot - location of new Sitecore Local instance [default=d:\webs,c:\inetpub\wwwroot]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [alias('www')]
        [string]$wwwroot = "",
        
        # solrRoot of new Sitecore Local instance [default=\solr\solr-[version[8.1.1]]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrRoot = "",

        # solrService of new Sitecore Local instance [default=solr-[version[8.1.1]]]]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrService = "",
        
        # solrService of new Sitecore Local instance [default=8.1.1]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrVersion = "8.4.0",

        # solrUrl of new Sitecore Local instance [default=localhost]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrHost = "localhost",

        # solrUrl of new Sitecore Local instance [default=8[version[811]]]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrPort = "",
        
        # solrUrl of new Sitecore Local instance [default=https://localhost:8[version[811]]/solr]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [string]$solrUrl = "",
        
        # Identity Server Site Name of new Sitecore Local instance [default=$hostname-si]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [alias('IdentityServerName')]
        [string]$idName = "",
        
        # xConnect Site Name of new Sitecore Local instance [default=$hostname-xconnect]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [alias('xConnectSiteName')]
        [string]$xcName = "",

        # Root path to assets [default=packages\assets]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string] $assetsRoot = "",
        
        # certificats path for certificates [default=assets\certs]
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$certs = "",
        
        # packages path for downloaded Sitecore packages [default=\repos\docker-images\build\packages]
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$packages = "",
        
        # LogFolder path for logs [default=.\logs]
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
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
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp
    if ($parametersResults.output) { Write-Host $parametersResults.output -ForegroundColor Green }
	#$parameters = $parametersResults.parameters

    
    if ([string]::IsNullOrEmpty($assetsRoot)) {
        $srcIndex = $PSScriptRoot.IndexOf("src")
        if ($srcIndex -ne -1) {
            $PSRepoRoot = $PSScriptRoot.Substring(0, $srcIndex)
            $assetsRoot = Join-Path $PSRepoRoot "assets"
        } else {
            $assetsRoot = Join-Path $PSScriptRoot "assets"
        }
    }

    if ($prefix -eq '$version'){ $prefix = ($version.Replace(".", "") + ".$name") }
    if ([string]::IsNullOrEmpty($hostname)) { $hostname = "$prefix$suffix" }

    if ([string]::IsNullOrEmpty($ConfigurationRoot)) { $ConfigurationRoot = Join-Path $assetsRoot "configs\$version\$ConfigurationTemplate" }
    if ([string]::IsNullOrEmpty($ConfigurationFile)) { $ConfigurationFile = Join-Path $ConfigurationRoot "$hostname.json" }

    # Replace the values in this file with your installation Overrides
    # all objects in the install-settings.json file can be overridden in this file

    # You can remove any items that you do not need to override. Keep in mind the dependency on other settings when removing items.
    # For example, $assets is used in various sections.

    Write-Host "Setting Local Overrides in $ConfigurationFile"

    #todo - merge these instead??!??
    $config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json

    # Assets and prerequisites
    $assets = $config.assets
    if ([string]::IsNullOrEmpty($LicenseFile) -and $assets.licenseFilePath -ne $LicenseFile) { $assets.licenseFilePath = $LicenseFile }
    if ([string]::IsNullOrEmpty($ConfigurationRoot)) { $ConfigurationRoot = $assets.configurationRoot }

    #$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    #Write-Host "repoRoot:$repoRoot"

    #$reposRoot = Split-Path $repoRoot -Parent
    #Write-Host "reposRoot:$reposRoot"

    #check for docker-images first - since it is most modern

    #$testPath = Join-Path (Join-Path $reposRoot "docker-images") "assets\license\license.xml"
    #if (Test-Path $testPath) {
    #    $assets.licenseFilePath = $testPath  
    #} else {
    #    $assets.licenseFilePath = Join-Path $repoRoot "assets\license\license.xml"
    #}

    # Settings
    #$parametersUser = Get-Content -Raw "..\local.parameters.json.user" -ErrorAction SilentlyContinue | ConvertFrom-Json

    # Site Settings
    $site = $config.settings.site
    
    $site.prefix = $prefix
    $site.suffix = $suffix
    $site.hostName = $hostname
    if ([string]::IsNullOrEmpty($site.hostName)) { $site.hostName = $config.settings.site.prefix + $config.settings.site.suffix }
    if ($wwwroot -AND $wwwroot -ne $site.webroot) {	$site.webroot = $wwwroot }
    
    Write-Host "Settings Sitecore Overrides"

    # Sitecore Parameters
    $sitecore = $config.settings.sitecore
    if ($scPwd -AND $scPwd -ne $sitecore.adminPassword) { $sitecore.adminPassword = $scPwd }
    #if ($scUser -AND $scUser -ne $sitecore.adminPassword) { $sitecore.adminPassword = $scUser }
    #$sitecore.singleDeveloperConfigurationPath = (Get-ChildItem $ConfigurationRoot -filter $ConfigurationFile -Recurse).FullName
    #$sitecore.exmCryptographicKey = "0x0000000000000000000000000000000000000000000000000000000000000000"
    #$sitecore.exmAuthenticationKey = "0x0000000000000000000000000000000000000000000000000000000000000000"
    #$sitecore.telerikEncryptionKey = "PutYourCustomEncryptionKeyHereFrom32To256CharactersLong"

    Write-Host "Settings SOLR Overrides"
    $solr = $config.settings.solr
    
    if ($solrRoot -AND $solrRoot -ne $solr.root) { $solr.root = $solrRoot }
    if ($solrUrl -AND $solrUrl -ne $solr.url) { $solr.url = $solrUrl }
    if ($solrService -AND $solrService -ne $solr.serviceName) { $solr.serviceName = $solrService }

    #$solr.url = "https://localhost:8811/solr" #"https://host:8750/solr"
    #$solr.root = $parametersUser.parameters.solrRoot.value #"d:\solr\solr-7.5.0" #"\\mac\users\davidwalker\containers\solr\7.5.0\solr_home"
    #$solr.serviceName = "Solr-8.1.1"
	#$solr.root = "d:\solr\" + $solr.serviceName 
    
    Write-Host "Settings SQL Overrides"
    $sql = $config.settings.sql
	$SqlSaPassword = "$((Get-ComputerDescription).Replace(' ',''))Rocks!"
    #$SqlSaPassword = $parametersUser.parameters.sqlAdminPassword.value
    $SqlStrongPassword = $SqlSaPassword # Used for all other services
    #$sql.server = $parametersUser.parameters.sqlServer.value
    #$sql.adminUser = $parametersUser.parameters.sqlAdminUser.value

    # #### EXAMPLE additional bindings
    # $otherAdditionalBinding = [ordered]@{
    #     hostName = "otherexample.dev.local"
    #     createCertificate = $false
    #     port = 443
    # }
    # $otherAdditionalBinding = $otherAdditionalBinding | ConvertTo-Json
    # $site.additionalBindings += (ConvertFrom-Json -InputObject $otherAdditionalBinding)

    ##### You should not need to modify settings below

    $sql.adminPassword = $SqlSaPassword
    $sql.userPassword = $SqlStrongPassword
    $sql.coreUser =  "coreuser"
    $sql.corePassword = $SqlStrongPassword
    $sql.masterUser =  "masteruser"
    $sql.masterPassword = $SqlStrongPassword
    $sql.webUser =  "webuser"
    $sql.webPassword = $SqlStrongPassword
    $sql.collectionUser =  "collectionuser"
    $sql.collectionPassword = $SqlStrongPassword
    $sql.reportingUser =  "reportinguser"
    $sql.reportingPassword = $SqlStrongPassword
    $sql.processingPoolsUser =  "poolsuser"
    $sql.processingPoolsPassword = $SqlStrongPassword
    $sql.processingTasksUser =  "tasksuser"
    $sql.processingTasksPassword = $SqlStrongPassword
    $sql.referenceDataUser =  "referencedatauser"
    $sql.referenceDataPassword = $SqlStrongPassword
    $sql.marketingAutomationUser =  "marketingautomationuser"
    $sql.marketingAutomationPassword = $SqlStrongPassword
    $sql.formsUser =  "formsuser"
    $sql.formsPassword = $SqlStrongPassword
    $sql.exmMasterUser =  "exmmasteruser"
    $sql.exmMasterPassword = $SqlStrongPassword
    $sql.messagingUser =  "messaginguser"
    $sql.messagingPassword = $SqlStrongPassword
    $sql.securityuser =  "securityuser"
    $sql.securityPassword = $SqlStrongPassword

    Write-Host "Settings xConnect Overrides"
    # XConnect Parameters
    $xConnect = $config.settings.xConnect
    if ($xcName -AND $xcName -ne $xConnect.siteName) { $xConnect.siteName = $xcName }
    $xConnect.siteRoot = Join-Path $site.webRoot -ChildPath $xConnect.siteName

    # IdentityServer Parameters
    $identityServer = $config.settings.identityServer
    if ($idPkg -AND $idPkg -ne $identityServer.packagePath) { $identityServer.packagePath = $idPkg }
    if ($idName -AND $idName -ne $identityServer.name) { $identityServer.name = $idName }
    $identityServer.url = ("https://{0}" -f $idName)
    $identityServer.clientSecret = $idName #"ClientSecret"

    Write-Host "Setting modules parameters in $ConfigurationFile"
    # Modules

    Function Reset-Path {
        param(
            $module,
            $root
        )
        $module.fileName = (Join-Path $root ("\modules\{0}" -f $module.fileName))
    }

    if (!$assetsJsonPath) { $assetsJsonPath = Join-Path $ConfigurationRoot 'assets-basic.json' }

    $RunModules = $true
    if ($RunModules) {
        Write-Host "Running Modules from:$assetsJsonPath" -ForegroundColor Cyan
        $modulesConfig = Get-Content $assetsJsonPath -Raw -Encoding Ascii | ConvertFrom-Json
        $modules = $config.modules
        $sitecore = $modulesConfig.sitecore

        $moduleConfig = @{
            id          = $sitecore.id
            name        = $sitecore.name
            fileName    = Join-Path $assets.packageRepository ("\{0}" -f $sitecore.fileName)
            url         = $sitecore.url
            extract     = $sitecore.extract
            install     = $sitecore.install
            source      = $sitecore.source
            databases   = $sitecore.databases
        }
        $moduleConfig = $moduleConfig| ConvertTo-Json
        $modules += (ConvertFrom-Json -InputObject $moduleConfig)

        foreach ($module in $modulesConfig.modules) {
            Reset-Path $module $assets.packageRepository
        }
        $modules += $modulesConfig.modules

        $config.modules = $modules
    }
	
	Write-Verbose "Saving: $config"
	Set-Content $ConfigurationFile (ConvertTo-Json -InputObject $config -Depth 6)
	Write-Host ("Saved:{0}" -f $ConfigurationFile) -InformationVariable results -ForegroundColor Green
	
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}