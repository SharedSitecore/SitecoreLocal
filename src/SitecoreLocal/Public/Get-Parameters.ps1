#Set-StrictMode -Version Latest
#####################################################
# Get-Parameters
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
PS> .\Get-Parameters 'name'

.EXAMPLE
PS> .\Get-Parameters 'name' 'template'

.EXAMPLE
PS> .\Get-Parameters 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Get-Parameters 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal

.OUTPUTS
    System.String
#>
Function Get-Parameters {
	Param(
		[hashtable]$Parameters,
		[hashtable]$BoundParameters, 
		[string]$Message = "", 
		[string[]]$Excludes = @('Confirm','Debug','ErrorAction','ErrorVariable','InformationAction','InformationVariable','OutBuffer','OutVariable','PipelineVariable','WarningAction','WarningVariable', 'WhatIf'),
		[datetime]$Started,
		[switch]$Show,
		[switch]$Stamp,
		[switch]$StartWatch,
		[switch]$StopWatch
	)
	$params = @{}
	$errorMessage = ""
	try {
		$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
		Write-Verbose "#####################################################"
		Write-Verbose "# $PSScriptName $Message -Show:$Show"
		
		#todo: loop thru bound first

		foreach($h in $Parameters.GetEnumerator()) {
			try {
				$key = $h.Key
				$value = Get-Variable -Name $key -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value -ErrorAction SilentlyContinue
				if (([String]::IsNullOrEmpty($value) -and (!$BoundParameters.ContainsKey($key)))) {
					#throw "A blank value that wasn't supplied by the user."
				}
				if ($Excludes.Contains($key)) { continue }
				
				$params[$key] = $value
				
			} catch {
				Write-Host "ERROR:$_" -InformationVariable errorMessage
			}

			Write-Verbose "# $($h.key):$($params[$key])"
		}
	} catch {
	  #Write-Host "An error occurred:"
	  #Write-Host $_
	}
	$PSScriptCaller = (Get-PSCallStack | Select-Object FunctionName -Skip 2 -First 1)
	Write-Host "PSScriptCaller:$PSScriptCaller"
	$output = ""
	if ($StopWatch -and $Started) { $Message = "$Message - {0:HH:mm:ss}" -f ([datetime]($(get-date) - $Started).Ticks)}
	if ($Message.Trim().Length -gt 0) { $output = "$output# $Message`n" }
	if ($Stamp) { $output = "$output# {0:yyyy-MM-dd hh:mm:ss} $($MyInvocation.MyCommand.Name)`n# Caller: $($PSScriptCaller.FunctionName)`n" -f (Get-Date) }
	if ($Show) { 
		$paramsString = ($params | Format-Table -AutoSize -Wrap| Out-String).Trim()
		if ($paramsString) { $output = "$output# parameters`n$paramsString`n" }
	}
	$results = @{
		output = "#####################################################`n$output#####################################################`n"
		parameters = $params
		PSScriptCaller = $PSScriptCaller
	}
	if ($StartWatch) { $results.started = Get-Date }

	#Write-Verbose "$PSScriptName.output:$($results.output)"
	#Write-Verbose "$PSScriptName.parameters:$($results.parameters)"
	return $results
}