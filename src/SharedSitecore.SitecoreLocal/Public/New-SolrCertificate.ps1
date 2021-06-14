#Set-StrictMode -Version Latest
#####################################################
# New-SolrCertificate
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
PS> .\Enable-ContainedDatabases 'name'

.EXAMPLE
PS> .\Enable-ContainedDatabases 'name' 'template'

.EXAMPLE
PS> .\Enable-ContainedDatabases 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Enable-ContainedDatabases 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function New-SolrCertificate {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )	
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):start" -Show -Stamp).output
    
    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
    $solr = $config.solr

	#. $PSScriptRoot\..\settings.ps1 #?>>SD??

	$SolrKeyFile = "$solr.root\server\etc\solr-ssl.keystore.jks"
	if ((Test-Path($SolrKeyFile))) {
		$SolrUri = [System.Uri]$solr.url
		
		#. $PSScriptRoot\Certificates\solr-ssl.ps1 -KeystoreFile "$SolrKeyFile" -SolrDomain $solr.service -Clobber
	}
}