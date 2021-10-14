#Set-StrictMode -Version Latest
#####################################################
# Enable-ContainedDatabases
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
Function Enable-ContainedDatabases {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
	Param
    (
		[Parameter(Mandatory=$false, Position=0)] [string]$server = '.',
		[Parameter(Mandatory=$false, Position=1)] [string]$user = 'sa',
		[Parameter(Mandatory=$false, Position=2)] [string]$password,
		[Parameter(Mandatory=$false, Position=2)] [string]$logs = '',
		[Parameter(Mandatory=$false, Position=2)] [string]$sharedResourcePath
	)
	#Enable Contained Databases
	Write-Host "Enable contained databases" -ForegroundColor Green
	$params = @{
		Path             = (Join-Path $$sharedResourcePath "enable-contained-databases.json")
		SqlServer        = $sserver
		SqlAdminUser     = $user
		SqlAdminPassword = $password
	}
	if (!$logs) { $logs = Join-Path $PWD "logs" }
	Install-SitecoreConfiguration @params -Verbose -WorkingDirectory $logs
}