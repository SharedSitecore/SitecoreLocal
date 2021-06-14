#Set-StrictMode -Version Latest
#####################################################
# New-ModuleInstallationConfiguration
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
PS> .\New-ModuleInstallationConfiguration

.EXAMPLE
PS> .\New-ModuleInstallationConfiguration 'configfile.json'

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function New-ModuleInstallationConfiguration {	
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
        # Path to Configuration File [ assets\configs\[version[\.]\XP0-SitecoreLocal.json]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [Parameter(Mandatory=$false)]
		[string] $ConfigurationFile
    )	
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"

	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):start" -Show -Stamp).output    
	
    if ([string]::IsNullOrEmpty($ConfigurationFile)) {
        $PSScriptPath = Join-Path $PSScriptRoot $MyInvocation.MyCommand.Name
        $PSScriptFolder = Split-Path $PSScriptPath -Parent
        #$PSRootDrive = if (Get-PSDrive 'd') { 'd:' } else { 'c:' }
        $PSRepoPath = Split-Path $PSScriptFolder -Parent
        if ($PSRepoPath.IndexOf('src') -ne -1) {
            $PSRepoPath = Split-Path (Split-Path $PSRepoPath -Parent) -Parent
        }
        if (!$assets) { $assets = Join-Path $PSRepoPath "assets" }
        if (!$certs) { $certs = Join-Path $assets "certs" }
        if (!$configRoot) {	$configRoot = Join-Path $assets "configs\$version\$ConfigurationTemplate" }
        if (!$ConfigurationFile) { $ConfigurationFile = Join-Path $configRoot "XP0-SitecoreLocal.json" }
    }

    $config = Get-Content -Raw $ConfigurationFile -Encoding Ascii | ConvertFrom-Json
    $modules = $config.modules
	Write-Verbose "modules:$($modules | Out-String)"
	$sharedResourcePath = Join-Path $assets.sharedUtilitiesRoot "assets\configuration"
	Write-Verbose "sharedResourcePath:$sharedResourcePath"

	#$modulesInstallable = $modules | Where-Object -Property install -NE $null | Where-Object { $_.install -eq $true -and $_.id -ne "sat" }
	$modulesInstallable = $modules | Where-Object -ErrorAction SilentlyContinue { (Test-Property $_ 'install') -and $_.install -eq $true -and $_.id -ne "sat" }
	Write-Verbose "modules:$($modulesInstallable | Out-String)"

	#$installableModules = $modules | Where-Object -Property install -NE $null | Where-Object { $_ -ne $null -and $_.install -eq $true -and $_.id -ne "sat" }
	$installableModules = $modules | Where-Object { $_.install -eq $true -and $_.id -ne "sat" } -ErrorAction SilentlyContinue
	$moduleConfigurationTemplate = Join-Path $sharedResourcePath "templates\module-install-template.json"
	$moduleMasterInstallConfigurationTemplate = Join-Path $sharedResourcePath "templates\module-master-install-template.json"

	$moduleMasterInstallationConfiguration = Join-Path $assets.configurationRoot "module-installation\module-master-install.json"
	$moduleInstallationConfiguration = Join-Path $assets.configurationRoot "module-installation\install-modules.json"

	$template = Get-Content $moduleConfigurationTemplate -Raw | ConvertFrom-Json
	$destination = Get-Content $moduleConfigurationTemplate -Raw | ConvertFrom-Json

	$masterConfiguration = Get-Content $moduleMasterInstallConfigurationTemplate -Raw | ConvertFrom-Json

	foreach ($installableModule in $installableModules) {
		$moduleParameters = New-Object PSObject
		$source = @{
			Source = Join-Path $sharedResourcePath "download-and-install-module.json"
		}
		$destination.Includes | Add-Member -Type NoteProperty -Name  $installableModule.id -Value $source

		$template.parameters | Get-ObjectMembers | ForEach-Object {
			$key = $_.Key
			$_.Value | Get-ObjectMembers | Foreach-Object {
				if ($_.Key -eq "Type") {
					$value = @{
						$_.key    = $_.value
						Reference = $key
					}
					$moduleParameters | Add-Member -MemberType NoteProperty -Name ($installableModule.id + ':' + $key) -Value (ConvertTo-Json -InputObject $value | ConvertFrom-Json)
				}
			}
		}
		$moduleConfiguration = @{
			Type         = "psobject"
			DefaultValue = $installableModule
		}
		$moduleParameters | Add-Member -MemberType NoteProperty -Name ($installableModule.id + ':' + "ModuleConfiguration") -Value (ConvertTo-Json -InputObject $moduleConfiguration | ConvertFrom-Json)
		try {
			if ($null -ne $installablemodule.additionalInstallationSteps) {
				$additionalSteps = Get-Content $([io.path]::combine($sharedResourcePath, $installableModule.id, $installableModule.additionalInstallationSteps)) -Raw | ConvertFrom-Json

				$additionalSteps.Includes | Get-ObjectMembers | ForEach-Object { $masterConfiguration.Includes | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value -Force }
				$additionalSteps.Parameters | Get-ObjectMembers | Foreach-Object { $masterConfiguration.Parameters | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value -Force }
				if ($null -ne $additionalSteps.Variables) {
					$additionalSteps.Variables | Get-ObjectMembers | Foreach-Object { $masterConfiguration.Variables | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value -Force }
				}
			}
		} catch { }
		$moduleParameters | Get-ObjectMembers | ForEach-Object { $destination.parameters | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value }
	}

	Set-Content $moduleMasterInstallationConfiguration (ConvertTo-Json -InputObject $masterConfiguration -Depth 5) -Force

	Set-Content $moduleInstallationConfiguration (ConvertTo-Json -InputObject $destination -Depth 5) -Force
}