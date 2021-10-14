#Set-StrictMode -Version Latest
#####################################################
#  Install-ModuleFromGithub
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
PS> .\Install-ModuleFromGithub 'name'

.EXAMPLE
PS> .\Install-ModuleFromGithub 'name' 'template'

.EXAMPLE
PS> .\Install-ModuleFromGithub 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-ModuleFromGithub 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
#TODO:COMBINE WITH INSTALL-MODULEIFMISSING
Function Install-ModuleFromGithub {
	Param (
		[string]$UriBase, 
		[string]$ModuleName
	)
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$PSScriptName ended" -Show
	Write-Host $parametersResults.output -ForegroundColor Green

	$moduleFolder = "c:\Program Files\WindowsPowerShell\Modules\$ModuleName\"
	Remove-Item $moduleFolder -Recurse -ErrorAction Ignore
	New-Item -ItemType Directory -Force -Path $moduleFolder | Out-Null

	$psm = "$ModuleName.psm1"
	Invoke-RestMethod ($UriBase) -OutFile ($moduleFolder + $psm)
}