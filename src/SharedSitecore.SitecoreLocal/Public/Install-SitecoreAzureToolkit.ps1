#Set-StrictMode -Version Latest
#####################################################
# Install-SitecoreAzureToolkit
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
PS> .\Install-SitecoreAzureToolkit 'name'

.EXAMPLE
PS> .\Install-SitecoreAzureToolkit 'name' 'template'

.EXAMPLE
PS> .\Install-SitecoreAzureToolkit 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-SitecoreAzureToolkit 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Install-SitecoreAzureToolkit {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param
    (
        # Path to Configuration File [ version
        [Parameter(Mandatory=$false)]
        [string] $ConfigurationFile = "",

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationRoot = "",

		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$ConfigurationFileName = "XP0-SitecoreLocal.json"
		
    )
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp
	Write-Host $parametersResults.output -ForegroundColor Green

	if (!$ConfigurationFile) {
		$PSScriptPath = Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name
		Write-Host "PSScriptPath:$PSScriptPath"

		$PSScriptFolder = Split-Path $PSScriptPath -Parent
		$PSRootDrive = if (Get-PSDrive 'd') { 'd:' } else { 'c:' }
		$PSRepoPath = Split-Path $PSScriptFolder -Parent
		if ($PSRepoPath.IndexOf('src') -ne -1) {
			$PSRepoPath = Split-Path (Split-Path $PSRepoPath -Parent) -Parent
		} else {
			$PSRepoPath = Join-Path $PSRootDrive '\repos\SharedSitecore.SitecoreLocal'
		}

		if(!$assetsRoot){ $assetsRoot = Join-Path $PSRepoPath 'assets' }
		Write-Host "assetsRoot:$assetsRoot"
		if (!$ConfigurationRoot) { $ConfigurationRoot = Join-Path $assetsRoot "configs\$version\$ConfigurationTemplate" }
		Write-Host "ConfigurationRoot:$ConfigurationRoot"
		if (!$ConfigurationFile) { $ConfigurationFile = Join-Path $ConfigurationRoot $ConfigurationFileName }
	}

    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
    if (!$config) {
        throw "Error trying to load configuration!"
    }

    $modules = $config.modules

	# Download Sitecore Azure Toolkit (used for converting modules)
	$package = $modules | Where-Object { $_.id -eq "sat" }

	Set-Alias sz 'C:\Program Files\7-Zip\7z.exe'

	$destination = $package.fileName

	if (!(Test-Path $destination)) {
		#Get-SitecoreDevCredentials

		$params = @{
			Path         = $([io.path]::combine($sharedResourcePath, 'download-assets.json'))
			#LoginSession = $global:loginSession
			Source       = $package.url
			Destination  = $destination
		}
		$Global:ProgressPreference = 'SilentlyContinue'
		Install-SitecoreConfiguration  @params  -Verbose
		$Global:ProgressPreference = 'Continue'
	}
	if ((Test-Path $destination) -and ( $package.install -eq $true)) {
		sz x -o"$($assets.sitecoreazuretoolkit)" $destination  -y -aoa
	}
	Import-Module (Join-Path $assets.sitecoreazuretoolkit "tools\Sitecore.Cloud.CmdLets.dll") -Force
}