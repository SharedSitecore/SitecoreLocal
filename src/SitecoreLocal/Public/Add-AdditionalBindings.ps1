#Set-StrictMode -Version Latest
#####################################################
# Add-AdditionalBindings
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
Function Add-AdditionalBindings {
    [CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param
    (
        [Parameter(Mandatory=$false)]
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))

    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
	$assets = $config.assets
    $site = $config.settings.site
    
    foreach ($binding in $site.additionalBindings) {
        $params = @{
            Path            = $site.addSiteBindingWithSSLPath
            SiteName        = $site.hostName
            WebRoot         = $site.webRoot
            HostHeader      = $binding.hostName
            Port            = $binding.port
            CertPath        = $assets.certificatesPath
            CertificateName = $binding.hostName
            Skip            = @()
        }
        if ($false -eq $binding.createCertificate) {
            $params.Skip += "CreatePaths", "CreateRootCert", "ImportRootCertificate", "CreateSignedCert"
        }
        if ($binding.sslOnly) {
            $params.Skip += "CreateBindings"
        }

        Install-SitecoreConfiguration @params -WorkingDirectory $(Join-Path $PWD "logs") -InformationVariable results -Verbose

        $PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
        Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
    }
}