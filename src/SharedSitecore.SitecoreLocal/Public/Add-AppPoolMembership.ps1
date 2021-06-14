#Set-StrictMode -Version Latest
#####################################################
# Add-AppPoolMembership
#####################################################
<#PSScriptInfo

.VERSION 0.

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
Function Add-AppPoolMembership {
    [CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )
    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
    $site = $config.settings.site
    $xConnect = $config.settings.xConnect

    #Add ApplicationPoolIdentity to performance log users to avoid Sitecore log errors (https://kb.sitecore.net/articles/404548)

    try {
        Add-LocalGroupMember "Performance Log Users" "IIS AppPool\$($site.hostName)"
        Write-Host "Added IIS AppPool\$($site.hostName) to Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($site.hostName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }
    try {
        Add-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($site.hostName)"
        Write-Host "Added IIS AppPool\$($site.hostName) to Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($site.hostName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }
    try {
        Add-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($xConnect.siteName)"
        Write-Host "Added IIS AppPool\$($xConnect.siteName) to Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($site.hostName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }
    try {
        Add-LocalGroupMember "Performance Log Users" "IIS AppPool\$($xConnect.siteName)"
        Write-Host "Added IIS AppPool\$($xConnect.siteName) to Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($xConnect.siteName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }

    $results = "end"
    $PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}