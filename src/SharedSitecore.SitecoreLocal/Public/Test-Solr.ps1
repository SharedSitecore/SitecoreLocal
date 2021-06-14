#Set-StrictMode -Version Latest
#####################################################
#  Test-Solr
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
Function Test-Solr {
	Param
    (
		# url
		[Parameter(Mandatory=$true)]
		[string]$url,

		# root
		[Parameter(Mandatory=$true)]
		[string]$root,

		# serviceName
		[Parameter(Mandatory=$true)]
		[string]$serviceName,

		# downloadFolder
		[Parameter(Mandatory=$true)]
		[string]$downloadFolder,

		# required - throw error if false
		[Parameter(Mandatory=$false)]		
		[switch]$required
	)
	if (-not $url.ToLower().StartsWith("https")) {
		Write-Error "Solr URL $($url) must be secured with https"
		return $false
	}
	
	try {
		if (Test-Path "$($root)\server") {
			if (Test-Service $serviceName) {
				$urlResults = Test-Url $url
				return $urlResults.Success
			} else {
				Write-Verbose "The Solr Service '$($serviceName)' does not exist?"
			}
		} else {
			Write-Verbose "The Solr root path '$($root)' appears invalid. A 'server' folder should be present in this path to be a valid Solr distributive."
		}
	}
	finally {
	}

	if ($required) {
		throw "Test-Solr($url):failed"
	}
	return $false
}