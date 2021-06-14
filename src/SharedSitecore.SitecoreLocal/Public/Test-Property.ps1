#Set-StrictMode -Version Latest
#####################################################
#  Test-Property
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
PS> .\Test-Property 'name'

.EXAMPLE
PS> .\Test-Property 'name' 'template'

.EXAMPLE
PS> .\Test-Property 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Test-Property 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Test-Property {
	Param
    (
		# Object
		[Parameter(Mandatory=$true)]
		[object]$object,

		# Name of property
		[Parameter(Mandatory=$true)]
		[string]$name
	)
	return $name -in $object.PSobject.Properties.Name;
}