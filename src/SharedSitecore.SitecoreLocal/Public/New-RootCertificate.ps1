#Set-StrictMode -Version Latest
#####################################################
# New-RootCertificate
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
Function New-RootCertificate {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        [string] $ConfigurationFile = "XP0-SitecoreLocal.json"
    )	
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):start" -Show -Stamp).output
    
    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json

    $xconnect = $config.settings.xconnect
    $XConnectCertStore = "Cert:\LocalMachine\My"

    $PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):start" -Show -Stamp).output
    
    $rootCert = New-SelfSignedCertificate -certstorelocation $XConnectCertStore -dnsname "Self-signed Certificate Authority" -FriendlyName "Self-signed Certificate Authority" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") -NotAfter (Get-Date).AddYears(10) -KeyUsage CertSign -KeyProtection None -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'
    try {
        $tempFile = New-TemporaryFile
        try {
            $pwd = ConvertTo-SecureString -String "secret" -Force -AsPlainText
            Export-PfxCertificate -cert $rootCert -FilePath $tempFile.FullName -Password $pwd
            return Import-PfxCertificate -FilePath $tempFile.FullName -Password $pwd -CertStoreLocation $XConnectCertStore
        } finally {
            Remove-Item $tempFile.FullName
        }
    } finally {
        Remove-Item $rootCert.PSPath
    }
}