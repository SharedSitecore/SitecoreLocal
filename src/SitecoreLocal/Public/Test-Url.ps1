#Set-StrictMode -Version Latest
#####################################################
#  Test-Url
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
Function Test-Url {
	Param
    (
		# url
		[Parameter(Mandatory=$true, Position=0)]
		[string]$url,
		# test [default=200]
		[Parameter(Mandatory=$false)]
		[string]$test = '200'
	)
	$results = @{
		Success 	= $false
		Content 	= ""
		StatusCode 	= 0
	}
	#$response = $false
	try {
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		Write-Host "#####################################################" -ForegroundColor Pink
		Write-Host " $PSScriptName($url,$test):start" -ForegroundColor Green
		$request = [System.Net.WebRequest]::Create($url)
		$ErrorActionPreference = "SilentlyContinue"
		$response = $request.GetResponse()
		$results.StatusCode = $response.StatusCode
		$ErrorActionPreference = "Stop"
		Write-Host "$PSScriptName($url,$test):$($response)"
		if ($test -eq '200') {
			$results.success = $response.StatusCode -eq 200
			#return $response.StatusCode -eq 200 #combine with and some day
		}
	}
	finally {
		if ($response) {
			$response.Close()
		}
	}
	Write-Host "$PSScriptName($url,$test):$($results)"
	return $results
}