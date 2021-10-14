#Set-StrictMode -Version Latest
#####################################################
#  Install-SingleDeveloper
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
PS> .\Install-SingleDeveloper 'name'

.EXAMPLE
PS> .\Install-SingleDeveloper 'name' 'template'

.EXAMPLE
PS> .\Install-SingleDeveloper 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-SingleDeveloper 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Install-SingleDeveloper {
    [CmdletBinding()]
	Param(
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string] $ConfigurationFile = ""
	)
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

    $PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
    Write-Host $parametersResults.output -ForegroundColor Green
        
    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
    $site = $config.settings.site
    $xConnect = $config.settings.xConnect
    $sql = $config.settings.sql

    # $singleDeveloperParams = @{
        # Path                           = $sitecore.singleDeveloperConfigurationPath
        # SqlServer                      = $sql.server
        # SqlAdminUser                   = $sql.adminUser
        # SqlAdminPassword               = $sql.adminPassword
        # SqlCollectionPassword          = $sql.collectionPassword
        # SqlReferenceDataPassword       = $sql.referenceDataPassword
        # SqlMarketingAutomationPassword = $sql.marketingAutomationPassword
        # SqlMessagingPassword           = $sql.messagingPassword
        # SqlProcessingEnginePassword    = $sql.processingEnginePassword
        # SqlReportingPassword           = $sql.reportingPassword
        # SqlCorePassword                = $sql.corePassword
        # SqlSecurityPassword            = $sql.securityPassword
        # SqlMasterPassword              = $sql.masterPassword
        # SqlWebPassword                 = $sql.webPassword
        # SqlProcessingTasksPassword     = $sql.processingTasksPassword
        # SqlFormsPassword               = $sql.formsPassword
        # SqlExmMasterPassword           = $sql.exmMasterPassword
        # SitecoreAdminPassword          = $sitecore.adminPassword
        # SolrUrl                        = $solr.url
        # SolrRoot                       = $solr.root
        # SolrService                    = $solr.serviceName
        # Prefix                         = $site.prefix
        # XConnectCertificateName        = $xconnect.siteName
        # IdentityServerCertificateName  = $identityServer.name
        # IdentityServerSiteName         = $identityServer.name
        # LicenseFile                    = $assets.licenseFilePath
        # XConnectPackage                = $xConnect.packagePath
        # SitecorePackage                = $sitecore.packagePath
        # IdentityServerPackage          = $identityServer.packagePath
        # XConnectSiteName               = $xConnect.siteName
        # SitecoreSitename               = $site.hostName
        # PasswordRecoveryUrl            = "https://" + $site.hostName
        # SitecoreIdentityAuthority      = "https://" + $identityServer.name
        # XConnectCollectionService      = "https://" + $xConnect.siteName
        # ClientSecret                   = $identityServer.clientSecret
        # AllowedCorsOrigins             = ("https://{0}|https://{1}" -f $site.hostName, "habitathomebasic.dev.local") # Need to add to proper config
        # WebRoot                        = $site.webRoot
    # }

	$singleDeveloperParams = @{
		Path = $ConfigurationFile
		SqlServer = $sql.server
		SqlAdminUser = $sql.adminUser
		SqlAdminPassword = $sql.adminPassword
		SitecoreAdminPassword = $sitecore.adminPassword
		SolrUrl = $solr.url
		SolrRoot = $solr.root
		SolrService = $solr.serviceName
		Prefix = $site.prefix
		XConnectCertificateName = $xconnect.siteName
		IdentityServerCertificateName = $identityServer.name
		IdentityServerSiteName = $identityServer.name
		LicenseFile = $licenseFile # $assets.licenseFile
		XConnectPackage = $xconnect.packagePath
		SitecorePackage = $sitecore.packagePath
		IdentityServerPackage = $identityServer.packagePath
		XConnectSiteName = $xconnect.siteName
		SitecoreSitename = $hostName
		SitecoreIdentityAuthority = "https://" + $identityServer.name
		XConnectCollectionService = "https://" + $xconnect.siteName
		ClientSecret = $identityServer.clientSecret
		AllowedCorsOrigins = ("https://{0}|https://{1}" -f $site.hostName, "habitathomebasic.dev.local") # Need to add to proper config
		SitePhysicalRoot = $site.webRoot
    }
    Write-Host "singleDeveloperParams:$($singleDeveloperParams | Out-String)"
    #Write-Host $singleDeveloperParams | Out-String
    #Write-Host "sqlAdminPassword:$sqlAdminPassword"
    
    $configRoot = Split-Path $ConfigurationFile -Parent
    Push-Location $configRoot #(Join-Path $resourcePath "XP0")
    try {
        Install-SitecoreConfiguration @singleDeveloperParams
        $results = 'end'
    }
    catch {
        $results = "ERROR:$_"
    }
    
    Pop-Location
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $parametersResults.started
    Write-Host $parametersResults.output -ForegroundColor Green
    
}