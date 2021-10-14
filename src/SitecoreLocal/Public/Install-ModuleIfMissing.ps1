#Set-StrictMode -Version Latest
#####################################################
# Install-ModuleIfMissing
#####################################################
<#PSScriptInfo

.VERSION 0.0

.GUID a9acdf44-f91c-481b-8cb7-29365a706bf9

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
Checks if Module is installed, if missing, installs

.DESCRIPTION
Checks if Module is installed, if missing, installs

.EXAMPLE
PS> .\Install-ModuleIfMissing 'name'

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
#>
Function Install-ModuleIfMissing {
	Param
    (
		[Parameter(Mandatory=$true, Position=0)] [string]$name
		#todo: --RequiredVersion $installerVersion -Repository $psRepositoryName -Scope CurrentUser
	)
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	#$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	#$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$PSScriptName ended" -Show
	#Write-Host $parametersResults.output -ForegroundColor Green
	
	$results = $name
    $module = Get-Module -Name $name
    if ($module) { 
        #Write-Verbose "Install-ModuleIfMissing $($name): already installed"
		$results = 'Already installed'
    } else {
		if (-not (Get-Module -Name "SqlServer")) {
			#Write-Verbose "Install-ModuleIfMissing $($name): installing"
			try {
				if ($name.ToLower() -ne 'webadministration') {
					Install-Module $name -Force -AllowClobber -Scope CurrentUser
				}
				
				Import-Module $name -Force
				
				$results = 'installed'
			}
			catch {
				$results = 'ERROR $_'
			}
		}
	}
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output}