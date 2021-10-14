#Set-StrictMode -Version Latest
#####################################################
#  Install-SitecoreLocal
#####################################################
<#PSScriptInfo

.VERSION 0.1

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
Function Edit-CryptographyAlgorithmsBindingRedirect {
    $webConfigFilePath = Join-Path (Join-Path $site.webRoot $site.hostName) "Web.config"
    [xml]$text = Get-Content -Path $webConfigFilePath

    ($text.configuration.runtime.assemblyBinding.dependentAssembly | Where-Object { $_.assemblyIdentity.name -eq "System.Security.Cryptography.Algorithms" }).bindingRedirect.newVersion = "4.0.0.0"

    $text.save($webConfigFilePath)
}