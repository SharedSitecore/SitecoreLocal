#Set-StrictMode -Version Latest
#####################################################
# Get-ComputerDescription
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
PS> .\Get-ComputerDescription 'name'

.EXAMPLE
PS> .\Get-ComputerDescription 'name' 'template'

.EXAMPLE
PS> .\Get-ComputerDescription 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Get-ComputerDescription 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Get-ComputerDescription {
	Param(
        [string] $computer = "."
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	if ([string]::IsNullOrEmpty($computer) -or $computer -eq '.' -or $computer -eq 'localhost') {
		$computer = $env:computername
	}

	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose "#####################################################"
	Write-Verbose "# $PSScriptName $computer"

	$results = ''
	try {
		$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
		$RegKey= $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters")
		$results = $RegKey.GetValue("srvcomment")
	} catch {
		Write-Error $_
	}
	Write-Verbose "# $($PSScriptName):$results"
	Write-Verbose "#####################################################"
	return $results
}