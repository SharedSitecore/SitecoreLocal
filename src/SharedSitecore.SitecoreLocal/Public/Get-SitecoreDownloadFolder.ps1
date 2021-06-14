Function Get-SitecoreDownloadFolder {
	Param
    (
		# path if you want to use custom
		[Parameter(Mandatory=$false)]
		[string]$path = "",	
		# repos folder [default=\repos]
		[Parameter(Mandatory=$false)]
		[string]$repos = "",
		# scope [default=User]
		[Parameter(Mandatory=$false)]
		[string]$scope = "User"
	)
	if (!$repos) { 
		$root = if (Get-PSDrive d) { 'd' } else { 'c' }
		$repos = "$($root):\repos"
	}
	$results = "$repos\docker-images\build\packages"
	if (!(Test-Path $dockerImagesPackages)) {
		$results = Join-Path $PSScriptRoot "assets\packages"
	}
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show).output
	return $results
}