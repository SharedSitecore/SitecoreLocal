#Set-StrictMode -Version Latest
#####################################################
# Install-Modules
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
PS> .\Install-Modules 'name'

.EXAMPLE
PS> .\Install-Modules 'name' 'template'

.EXAMPLE
PS> .\Install-Modules 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-Modules 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Install-Modules
#####################################################
Function Install-Modules {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        # Path to Configuration File [ version
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigurationFile = '',

        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationRoot = '',

        # path if you want to use custom [default=[hostname].json]
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationFileName = '',
        
        # path if you want to use custom [default=[hostname].json]
        [Parameter(Mandatory=$false)]
        [string]$hostname = '',
        
        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationTemplate = 'XP0'
    )	
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
    Write-Host $parametersResults.output -ForegroundColor Green
    $started = $parametersResults.started

    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $StopWatch.Start()

    $ErrorActionPreference = 'Stop'

	if ([string]::IsNullOrEmpty($ConfigurationFile)) {
        $PSScriptPath = Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name
        $PSScriptFolder = Split-Path $PSScriptPath -Parent
        #$PSRootDrive = if (Get-PSDrive 'd') { 'd:' } else { 'c:' }
        $PSRepoPath = Split-Path $PSScriptFolder -Parent
        if ($PSRepoPath.IndexOf('src') -ne -1) {
            $PSRepoPath = Split-Path (Split-Path $PSRepoPath -Parent) -Parent
        }
        if (!$assets) { $assets = Join-Path $PSRepoPath "assets" }
        if (!$certs) { $certs = Join-Path $assets "certs" }
		if (!$ConfigurationRoot) {	$ConfigurationRoot = Join-Path $assets "configs\$version\$ConfigurationTemplate" }
		if ($hostname) {
			if (!$ConfigurationFileName) { $ConfigurationFileName = "$hostname.json" }
			if (!$ConfigurationFile) { $ConfigurationFile = Join-Path $ConfigurationRoot $ConfigurationFileName }
		}
    }

    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
	$assets = $config.assets
    $site = $config.settings.site
	$sitecore = $config.settings.sitecore
	$solr = $config.settings.solr
    $sql = $config.settings.sql
	$xConnect = $config.settings.xConnect

	Write-Host "SiteName:$($site.hostName)"
	#Write-Host "DatabasePrefix:$($site.prefix)"
	Write-Host "WebRoot:$($site.webRoot)"
	Write-Host "CorePrefix:$($site.prefix)"
	
	#$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	#$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$PSScriptName ended" -Show
	#Write-Host $parametersResults.output -ForegroundColor Green
	Write-Host "sitecoreVersion:$($assets.sitecoreVersion)"
	$version = $assets.sitecoreVersion
	if ($version.Contains(" ")) { $version = $version.Substring(0, $version.IndexOf(" ")) }
	Write-Host "version:$version"

	$bootLoaderPackagePath = [IO.Path]::Combine($assets.sitecoreazuretoolkit, "resources\$version\Addons\Sitecore.Cloud.Integration.Bootload.wdp.zip")
	$bootloaderConfigurationOverride = $([io.path]::combine($assets.sharedUtilitiesRoot, "assets", 'Sitecore.Cloud.Integration.Bootload.InstallJob.exe.config'))
	$bootloaderInstallationPath = $([io.path]::combine($site.webRoot, $site.hostName, "App_Data\tools\InstallJob"))

	Write-Host "bootLoaderPackagePath:$bootLoaderPackagePath"
	Write-Host "bootloaderConfigurationOverride:$bootloaderConfigurationOverride"
	Write-Host "bootloaderInstallationPath:$bootloaderInstallationPath"

	$moduleConfig = Join-Path $assets.configurationRoot "module-installation\module-master-install.json"
	Write-Host "moduleConfig:$moduleConfig"
	#Get-SitecoreDevCredentials

	$params = @{
		Path                            = $moduleConfig
		SiteName                        = $site.hostName
		WebRoot                         = $site.webRoot
		XConnectSiteName                = $xConnect.siteName
		SqlServer                       = $sql.server
		SqlAdminUser                    = $sql.adminUser
		SqlAdminPassword                = $sql.adminPassword
		DatabasePrefix                  = $site.prefix
		SecurityUserName                = $sql.securityUser
		SecurityUserPassword            = $sql.SecurityPassword
		CoreUserName                    = $sql.coreUser
		CoreUserPassword                = $sql.corePassword
		MasterUserName                  = $sql.masterUser
		MasterUserPassword              = $sql.MasterPassword
		BootLoaderPackagePath           = $bootLoaderPackagePath
		BootloaderConfigurationOverride = $bootloaderConfigurationOverride
		BootloaderInstallationPath      = $bootloaderInstallationPath
		#LoginSession                    = $global:loginSession
		SolrUrl                         = $solr.url
		SolrRoot                        = $solr.root
		SolrService                     = $solr.serviceName
		CorePrefix                      = $site.prefix
		SitecoreAdminPassword           = $sitecore.adminPassword
	}

	Write-Verbose "#####################################################`nInstall-Modules:`n$(($params | Format-Table -AutoSize -Wrap | Out-String).Trim())`n#####################################################"

	Push-Location $assets.configurationRoot
	$results = Install-SitecoreConfiguration @params -Verbose
	Pop-Location

	$StopWatch.Stop()
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $started
    Write-Host $parametersResults.output -ForegroundColor Green    
}