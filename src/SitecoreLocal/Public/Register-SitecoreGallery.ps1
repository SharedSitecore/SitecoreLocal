#Set-StrictMode -Version Latest
#####################################################
# Register-SitecoreGallery
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
PS> .\Install-SitecoreLocal 'name'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' 'template'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-SitecoreLocal 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
function Register-SitecoreGallery {
    Param
    (
		# PSRepository Url [default=https://sitecore.myget.org/F/sc-powershell/api/v2/]
		[Parameter(Mandatory=$false)]
		[string]$psRepository = 'https://sitecore.myget.org/F/sc-powershell/api/v2/',
		# Name of PSRepository [default=SitecoreGallery]
		[Parameter(Mandatory=$false)] [string]$psRepositoryName = 'SitecoreGallery'
	)
	$repositories = (Get-PSRepository | Where-Object { $_.Name -eq $psRepositoryName })
	#if (!$repositories) { $repositories = @()}
	#if (($repositories).Count -eq 0) {
	#if ((Get-PSRepository | Where-Object { $_.Name -eq $psRepositoryName }).count -eq 0) {
	if (!$repositories) {
		Write-Host "Register-PSRepository $($psRepositoryName)" -ForegroundColor Green
		Register-PSRepository -Name $psRepositoryName -SourceLocation $psRepository -InstallationPolicy Trusted
		$results = "$psRepositoryName installed."
	} else {
		$results = "$psRepositoryName already installed."
	}
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}