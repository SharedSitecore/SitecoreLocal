#Set-StrictMode -Version Latest
#####################################################
# Install-Tool
#####################################################
<#PSScriptInfo

.VERSION 0.0

.GUID 892ba205-076c-474e-bf60-9041e8ae40a9

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
PS> .\Install-Tool 'name'

.EXAMPLE
PS> .\Install-Tool 'name' 'template'

.EXAMPLE
PS> .\Install-Tool 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-Tool 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal
# Credit primarily to jermdavis for the original script
# and https://gitlab.com/viet.hoang/workshop/blob/master/Scripts%20for%20Sitecore%209.1/helper.psm1

.OUTPUTS
    System.String
#>
Function Install-Tool {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
    Param(
		# Source of Tool usually Url to .zip
        [string]$source,

		# Name of Tool
        [string]$name,

		# Version of Tool
		[string]$version,

		# Path where Tool is Installed [default=d:\tools\$name]
        [string]$path,

		# Name of package [default=name.zip]
		[string]$package,

		# Task to run after downloading
		[string]$task,

		# Packages path where packages are downloaded
		[alias('downloadFolder')]
        [string]$packages = 'd:\repos\docker-images\build\packages'
    )
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$parametersResults = Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp -StartWatch
	Write-Host $parametersResults.output -ForegroundColor Green
	$parameters = $parametersResults.parameters

	if (!$source) {
		if (Test-Path "$PSScriptName.pson") {
			$tools = Get-Content .\$PSScriptName.pson | ConvertFrom-StringData
			$source = $tools[$name]
		} else {
			Write-Error 'Must provide $source or $name'
		}
	} else {
		if (!$package) {
			$package = $source
			if ($package.IndexOf('\') -gt 1) { $package = $package.Remove(0, $package.LastIndexOf('\') + 1) }
			if ($package.IndexOf('/') -gt 1) { $package = $package.Remove(0, $package.LastIndexOf('/') + 1) }
			if(!$name) {
				$name = $package
				if ($name.IndexOf('.') -gt 1) { $name = $name.Substring(0, $name.LastIndexOf('.')) }
			}
		}
	}
	
	if (!$packages) { $packages = Get-SitecoreDownloadFolder }

	if (!$package) { $package = "$packages\$name.zip" }
	
	if (!$path) { 
		$root = if (Get-PSDrive 'd') {'d'} else {'c'}
		if ($name.IndexOf('solr') -eq -1) {
			$path = "$($root):\tools\$name"
		} else {
			$path = "$($root):\solr\$name"
		}
	}
	
    if(!(Test-Path -Path "$path"))
    {
		Write-Host " $PATH Test failed. Install:$name" -InformationVariable results -ForegroundColor Green	
        if(!(Test-Path -Path $package))
        {
			if ($name -ne 'java') {
				Write-Host "$PSScriptName $name:Start-BitsTransfer - start"
				Start-BitsTransfer -Source $source -Destination $package
			} else {
				#$source = "http://download.oracle.com/otn-pub/java/jdk/8u5-b13/jdk-8u5-windows-i586.exe"
				$destination = $package
				$client = new-object System.Net.WebClient 
				$cookie = "oraclelicense=accept-securebackup-cookie"
				$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie) 
				$client.downloadFile($source, $destination)
			}
        }

		if (!$task) {
			if ($name.StartsWith('solr')) {
				$path = $path | Split-Path -Parent
			}
			Write-Host "Extracting $name to $path..." -InformationVariable results	
			Expand-Archive $package -DestinationPath $path
		} else {
			Write-Host "Extracting $name to $packages\$name..."
			Expand-Archive $package -DestinationPath "$packages\$name"

			#$destination86 = "C:\vagrant\$JDK_VER-x64.exe"

			$installer = get-childitem -path "$packages\$name" | Where-Object {$_.Name.EndsWith('.exe')}

			#task = "/s REBOOT=ReallySuppress"
			if ($installer -and $task) {
				try {
					$proc1 = Start-Process -FilePath $installer -ArgumentList $task -Wait -PassThru
					$proc1.waitForExit()
					Write-Host 'Installation Done.' -InformationVariable results
				}
				finally {
				}
			}
		}
	} 
	else
	{
		$results = Write-Host "$name already installed." -InformationVariable results
    }
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -StopWatch -Started $parametersResults.started ).output
}