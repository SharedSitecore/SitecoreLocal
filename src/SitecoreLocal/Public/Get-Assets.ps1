#Set-StrictMode -Version Latest
#####################################################
# Get-Assets
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
PS> .\Get-Assets 'name'

.EXAMPLE
PS> .\Get-Assets 'name' 'template'

.EXAMPLE
PS> .\Get-Assets 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Get-Assets 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Get-Assets {
	Param(
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp
	Write-Host $parametersResults.output -ForegroundColor Green

	$json = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
	$modules = $json.modules
	$assets = $json.assets

	$downloadFolder = $assets.packageRepository
	#Write-Host "downloadFolder:$downloadFolder"
	
    # Download Sitecore
    if (!(Test-Path $downloadFolder)) {
		Write-Host "downloadFolder: $downloadFolder - missing, creating"
        New-Item -ItemType Directory -Force -Path $downloadFolder
    }
	#$modules = @()

	$sharedResourcePath = Join-Path $assets.sharedUtilitiesRoot "/assets/configuration"
	
    $downloadJsonPath = $([io.path]::combine($sharedResourcePath, 'download-assets.json'))
	#Write-Host "downloadJsonPath:$downloadJsonPath"

	if (Test-Path $downloadJsonPath) {
		Write-Host 'Test 7zip'
		if (Test-Path 'C:\Program Files\7-Zip\7z.exe') {
			$zipTool = 'C:\Program Files\7-Zip\7z.exe'
			Write-Host '7zip installed. Set-Alias sz'			
			Set-Alias sz $zipTool
		}

		$package = $modules | Where-Object { $_.id -eq "xp" }

		Write-Host ("Downloading {0} - if required" -f $package.name )

		$destination = $package.fileName

		if (!(Test-Path $destination)) {
			#Get-SitecoreDevCredentials //LoginSession = $global:loginSession
			$params = @{
				Path         = $downloadJsonPath				
				Source       = $package.url
				Destination  = $destination
			}
			$Global:ProgressPreference = 'SilentlyContinue'
			Install-SitecoreConfiguration  @params  *>&1 | Tee-Object $LogFile -Append
			$Global:ProgressPreference = 'Continue'
		}
		if ((Test-Path $destination) -and ( $package.extract -eq $true)) {
			Write-Host ("Checking {0}) - if exists/required" -f $package.name )
			if ($zipTool) {
				sz x -o"$DownloadFolder" $destination  -y -aoa
			}
			else {
				Expand-Archive $package -DestinationPath "$destination"
			}
		}
	} 
	else {
		Write-Host "$downloadJsonPath not found?"
	}
	
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName ended" -Show -Stamp
	Write-Host $parametersResults.output -ForegroundColor Green
}