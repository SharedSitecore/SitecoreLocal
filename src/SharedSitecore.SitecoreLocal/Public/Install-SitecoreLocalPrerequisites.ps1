#Set-StrictMode -Version Latest
#####################################################
# Install-SitecoreLocalPrerequisites
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
Function Install-SitecoreLocalPrerequisites {
    [CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param
    (
        # solr version
        [Parameter(Mandatory=$false)]
        [string]$solrVersion = '8.4.0',

        [Parameter(Mandatory=$false)]
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		
	#Install-RequiredInstallationAssets
	Register-SitecoreGallery	
	Install-SitecoreInstallFramework

	Get-Assets $ConfigurationFile

    Write-Host "Reading config"
    # Reset location to script root
    #Set-Location $PSScriptRoot

    $json = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
	$assets = $json.assets
	$downloadFolder = $assets.packageRepository

    Write-Host "Checking SOLR"

	#$solrInstalled = Test-Solr $solrUrl $solrRoot $solrService $downloadFolder
    Install-Solr -solrVersion $solrVersion -downloadFolder $downloadFolder
    #if(!$solrInstalled) {
    #    $solrInstalled = Install-Solr $solrUrl $solrRoot $solrService -downloadFolder $downloadFolder
    #}

    #Enable-ContainedDatabases
    Write-Host "Enable contained databases" -InformationVariable results -ForegroundColor Green

    #Verify that assets are present
    #if (!(Test-Path $assets.root)) {
        #throw "$($assets.root) not found"
    #}

    #Verify license file
    #if (!(Test-Path $assets.licenseFilePath)) {
        #throw "License file $($assets.licenseFilePath) not found"
    #}

    #Verify Sitecore package
    #if (!(Test-Path $sitecore.packagePath)) {
        #throw "Sitecore package $($sitecore.packagePath) not found"
    #}

    #Verify xConnect package
    #if (!(Test-Path $xConnect.packagePath)) {
       # throw "XConnect package $($xConnect.packagePath) not found"
    #}
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}