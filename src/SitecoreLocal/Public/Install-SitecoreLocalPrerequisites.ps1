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
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json",
        
        [Parameter(Mandatory=$false)]
        [string]$logs = '',

        [Parameter(Mandatory=$false)]
        [string]$sharedResourcePath = ''
    )
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
    $parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):start" -Show -Stamp -StartWatch
    Write-Host $parametersResults.output -ForegroundColor Green
    $started = $parametersResults.started

	#Install-RequiredInstallationAssets
    #Invoke-Expression '.\Install-IIS.ps1'

    $features=@(
    "IIS-WebServerRole",
    "IIS-WebServer",
    "IIS-CommonHttpFeatures",
    "IIS-HttpErrors",
    "IIS-HttpRedirect",
    "IIS-ApplicationDevelopment",
    "NetFx4Extended-ASPNET45",
    "IIS-NetFxExtensibility45",
    "IIS-HealthAndDiagnostics",
    "IIS-HttpLogging",
    "IIS-LoggingLibraries",
    "IIS-RequestMonitor",
    "IIS-HttpTracing",
    "IIS-Security",
    "IIS-RequestFiltering",
    "IIS-Performance",
    "IIS-WebServerManagementTools",
    "IIS-IIS6ManagementCompatibility",
    "IIS-Metabase",
    "IIS-ManagementConsole",
    "IIS-BasicAuthentication",
    "IIS-StaticContent",
    "IIS-DefaultDocument",
    "IIS-WebSockets",
    "IIS-ApplicationInit",
    "IIS-ISAPIExtensions",
    "IIS-ISAPIFilter",
    "IIS-HttpCompressionStatic",
    "IIS-ASPNET45"
    )
#    "IIS-WindowsAuthentication",
    #$features=@()
    #install windows features
    Write-Host "Checking Windows Features"
    $systemdrive = [Environment]::GetEnvironmentVariable('SystemDrive', 'Machine')
    if(!$systemdrive) {$systemdrive = 'c'}
    if (!(Test-Path(Join-Path "$($systemdrive):" '\inetpub\wwwroot'))) {
        Write-Verbose "=======Installing Windows Features========" -ForegroundColor Green
        foreach ($feature in $features) {
            Write-Verbose "=======Installing $feature========" -ForegroundColor Green
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -Verbose
            Write-Verbose "=======Installed $feature========" -ForegroundColor Green
        }
    }

	#Register-SitecoreGallery	
	#Install-SitecoreInstallFramework

	Get-Assets $ConfigurationFile

    Write-Host "Reading config"
    # Reset location to script root
    #Set-Location $PSScriptRoot

    $json = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
	$assets = $json.assets
	$downloadFolder = $assets.packageRepository

    Write-Host "Checking SOLR"

	#$solrInstalled = Test-Solr $solrUrl $solrRoot $solrService $downloadFolder
    Install-Solr -solrVersion $solrVersion -downloadFolder $downloadFolder -configurationRoot $assets.configurationRoot -verbose #-Clobber
    #if(!$solrInstalled) {
    #    $solrInstalled = Install-Solr $solrUrl $solrRoot $solrService -downloadFolder $downloadFolder
    #}

    if(!(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL')) {
        $installer = "$($assets.packageRepository)/SQL2019-SSEI-Dev.exe"
        if(!(Test-Path $installer)) {
            #https://go.microsoft.com/fwlink/?linkid=866662
        }
        #Install SQL
        #<Installation media location>\setup.exe /ACTION=install /QS /INSTANCENAME="<MachineName\InstanceName>" /IACCEPTSQLSERVERLICENSETERMS = 1 /FEATURES=SQLENGINE,SSMS /SQLSYSADMINACCOUNTS = "<YourDomain\Administrator>"
        $cmd = "$($assets.packageRepository)/SQL2019-SSEI-Dev.exe /ACTION=install /QS /INSTANCENAME=$($json.settings.sql.server) /IACCEPTSQLSERVERLICENSETERMS=1 /FEATURES=SQLENGINE,SSMS /SQLSYSADMINACCOUNTS=$($json.settings.sql.adminUser)"
        Write-Host "cmd:$cmd"
        $results = Invoke-Expression $cmd
        Write-Host "results:$results"
    }
    if(!(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL')) {
        throw 'SQL NOT INSTALLED'
    }

    Enable-ContainedDatabases $json.settings.sql.server $json.settings.sql.adminUser $json.settings.sql.adminPassword $logs "$($assets.sharedUtilitiesRoot)" #/assets/configuration"
    Write-Host "Enable contained databases" -InformationVariable results -ForegroundColor Green

    #Install-Prerequisites
    Install-SitecoreConfiguration -Path (Join-Path $assets.configurationRoot prerequisites.json)
    
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
	#$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	#Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output

    #$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$($PSScriptName):$results" -Show -StopWatch -Started $started
    #Write-Host $parametersResults.output -ForegroundColor Green

    #Write-Verbose "$PSScriptName $hostname $version end"
    Write-Verbose "$PSScriptName end"
}