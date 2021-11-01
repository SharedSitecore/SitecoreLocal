#Set-StrictMode -Version Latest
#####################################################
# Install-SitecoreInstallFramework
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
PS> .\Install-SitecoreInstallFramework 'name'

.EXAMPLE
PS> .\Install-SitecoreInstallFramework 'name' 'template'

.EXAMPLE
PS> .\Install-SitecoreInstallFramework 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-SitecoreInstallFramework 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
function Install-SitecoreInstallFramework {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
	Param
    (
		# installerVersion [default=2.3.0]
		[Parameter(Mandatory=$false)]
		[string]$installerVersion = "2.3.0",		
		# Name of PSRepository [default=SitecoreGallery]
		[Parameter(Mandatory=$false)] [string]$psRepositoryName = 'SitecoreGallery'
	)
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

	#$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	#$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp
	#Write-Host $parametersResults.output -ForegroundColor Green
	
	#Sitecore Install Framework dependencies
	#$module = Get-Module -FullyQualifiedName @{ModuleName = "SitecoreInstallFramework"; ModuleVersion = $assets.installerVersion }
	#if (-not (Get-Module -Name "WebAdministration")) {
	#	Import-Module WebAdministration -Force
	#}
	#if (-not (Get-Module -Name "SqlServer")) {
	#	Write-Verbose 'Installing Module'
	#	Install-Module SqlServer -Force -AllowClobber -Scope User
	#	Import-Module SqlServer -Force
	#}
	Install-ModuleIfMissing "WebAdministration"
	Install-ModuleIfMissing "SqlServer"

	#Install SIF
	Write-Host "Installing the Sitecore Install Framework, version $($installerVersion)" -ForegroundColor Green
	
	#Install-Module SitecoreInstallFramework -RequiredVersion $installerVersion -Repository $psRepositoryName -Scope CurrentUser
	Install-ModuleIfMissing SitecoreInstallFramework
	Import-Module SitecoreInstallFramework -RequiredVersion $installerVersion -InformationVariable results -Scope Global -Force
	

	#Import-SitecoreInstallFramework -version $assets.installerVersion
	
	#Install versus Import! .. see install-xc0.ps1 for code to update/patch SIF 2.1.0
    #Verify that manual assets are present
	#if (!(Test-Path $assets.root)) {
	#	throw "$($assets.root) not found"
	#}
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Host "$PSScriptName ended" -InformationVariable results
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}