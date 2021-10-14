#Set-StrictMode -Version Latest
#####################################################
# Install-SitecoreLocalModules
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
PS> .\Install-SitecoreLocalModules

.EXAMPLE
PS> .\Install-SitecoreLocalModules 'XP0-SitecoreLocal.json'

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#####################################################
# Install-SitecoreLocalModules
#####################################################
function Install-SitecoreLocalModules {
    [alias("in-sc-mods")]
    Param(
        # Path to Configuration File [ version
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [Parameter(Mandatory=$false)]
        [string] $ConfigurationFile = "",

        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationRoot = "",

        # path if you want to use custom [default=[hostname].json]
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationFileName = "",
        
        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationTemplate = "XP0",

        # Name of new Sitecore Local instance [default=dev]
		[Parameter(Mandatory=$false)] [string]$name = 'dev',

		# Version of new Sitecore Local instance [default=9.3.0]
		#[Parameter(Mandatory=$false)] [string]$version = "9.3.0",
        [Parameter(Mandatory=$false)] [string]$version = "10.1.0",

        # Prefix of new Sitecore Local instance [default=$version[\.].[name]]
		[Parameter(Mandatory=$false)] [string]$prefix = '$version',

		# Suffix of new Sitecore Local instance [default=.local]
		[Parameter(Mandatory=$false)] [string]$suffix = '.local'
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
    Write-Host $parametersResults.output -ForegroundColor Green
    $started = $parametersResults.started
    $PSScriptCaller = $parametersResults.PSScriptCaller

    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $StopWatch.Start()

    $ErrorActionPreference = 'Stop'
    Set-Location $PSScriptRoot

    #$LogFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LogFolder)
    #if (!(Test-Path $LogFolder)) {
    #    New-item -ItemType Directory -Path $LogFolder
    #}
    #$LogFile = Join-path $LogFolder $LogFileName
    #if (Test-Path $LogFile) {
    #     Get-Item $LogFile | Remove-Item
    #}

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
        if (!$ConfigurationRoot) { $ConfigurationRoot = Join-Path $assets "configs\$version\$ConfigurationTemplate" }


        if($prefix -eq '$version'){ $prefix = ($version.Replace(".", "") + ".") }
		#$prefix += "$name"
		if(!$hostname){ $hostname = "$prefix.$name.$suffix" }

        if (!$ConfigurationFileName) { $ConfigurationFileName = "$hostname.json" }
        if (!$ConfigurationFile) { $ConfigurationFile = Join-Path $ConfigurationRoot $ConfigurationFileName }
    }
    if (!$ConfigurationRoot) { $ConfigurationRoot = Split-Path $ConfigurationFile -Parent }

    if (!(Test-Path $ConfigurationFile)) {
        Write-Host "Configuration file '$($ConfigurationFile)' not found." -ForegroundColor Red
        Write-Host  "Please use 'set-installation...ps1' files to generate a configuration file." -ForegroundColor Red
        Exit 1
    }
    $config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
    if (!$config) {
        throw "Error trying to load configuration!"
    }
    $assets = $config.assets

    $sharedResourcePath = Join-Path $assets.sharedUtilitiesRoot "assets\configuration"
    Write-Host "sharedResourcePath:$sharedResourcePath"
    $downloadFolder = $assets.packageRepository
    $packagesFolder = (Join-Path $downloadFolder "modules")

    #$loginSession = $null

    Write-Host "PSScriptCaller:$($PSScriptCaller.FunctionName)"
    #if ($PSScriptCaller.FunctionName -eq 'Install-SitecoreLocalModules') {
        # if not called from Install-SitecoreLocal these are needed:
        Import-Module (Join-Path $assets.sharedUtilitiesRoot "assets\modules\SharedInstallationUtilities\SharedInstallationUtilities.psm1") -Force

        Import-Module SqlServer

        #Ensure the Correct SIF Version is Imported
        Import-SitecoreInstallFramework -version $assets.installerVersion -repositoryName $assets.psRepositoryName -repositoryUrl $assets.psRepository
    #}

    if (!(Test-Path $packagesFolder)) {
        New-Item $packagesFolder -ItemType Directory -Force  > $null
    }
    
    Install-SitecoreAzureToolkit $ConfigurationFile
    New-ModuleInstallationConfiguration $ConfigurationFile -Verbose
    Install-Modules $ConfigurationFile -Verbose
    $results = 'done'

    $StopWatch.Stop()
    $StopWatch

    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $started
    Write-Host $parametersResults.output -ForegroundColor Green    
}