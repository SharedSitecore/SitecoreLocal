#Set-StrictMode -Version Latest
#####################################################
# Install-Solr
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
PS> .\Install-Solr 'name'

.EXAMPLE
PS> .\Install-Solr 'name' 'template'

.EXAMPLE
PS> .\Install-Solr 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Install-Solr 'name' 'template' 'd:\repos' -Persist User

.Link
https://github.com/SitecoreDave/SharedSitecore.SitecoreLocal
# Credit primarily to jermdavis for the original script
# and https://gitlab.com/viet.hoang/workshop/blob/master/Scripts%20for%20Sitecore%209.1/helper.psm1

.OUTPUTS
    System.String
#>
Function Install-Solr {
	[CmdletBinding(SupportsShouldProcess,PositionalBinding=$true)]
	Param(
		[string]$solrVersion = "8.4.0",
		[string]$installFolder = "",
		[string]$solrPort = "8840",
		[string]$solrHost = "localhost",
		[bool]$solrSSL = $TRUE,
		[string]$nssmVersion = "2.24",
		[string]$keystoreSecret = "secret",
		[string]$KeystoreFile = 'solr-ssl.keystore.jks',
		[string]$SolrDomain = 'localhost',
		[string]$maxJvmMem = '512m',
		[string]$downloadFolder = '',
		[switch]$Clobber
	)
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	# Turning off progress bar to (greatly) speed up installation
	$Global:ProgressPreference = "SilentlyContinue"
	$ErrorActionPreference = 'Stop'
	$VerbosePreference = "SilentlyContinue"

	Write-Host 'boom'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):start" -Show -Stamp).output
	if (!$installFolder){
		$root = if (Get-PSDrive 'd' -ErrorAction SilentlyContinue) { 'd' } else { 'c' }
		$installfolder = "$($root):\solr"
	}
	$solrName = "solr-$solrVersion"
	$solrRoot = "$installFolder\$solrName"
	$nssmRoot = "$installFolder\nssm-$nssmVersion"
	$solrPackage = "http://archive.apache.org/dist/lucene/solr/$solrVersion/$solrName.zip"
	$nssmPackage = "http://nssm.cc/release/nssm-$nssmVersion.zip"

	$ConfigurationFile = "$MyInvocation.MyCommand.Name.parameters.json"
	if ((Test-Path "$ConfigurationFile.user")) {
		$ConfigurationFile = "$ConfigurationFile.user"
	}
	Write-Host "configurationFile:$configurationFile"	
	if ((Test-Path $ConfigurationFile)) {
		$config = Get-Content -Raw $ConfigurationFile | ConvertFrom-Json
		if ($config) {
			if ($config.SolrVersion) {
				$solrVersion = $config.solrVersion
			}
			if ($config.installFolder) {
				$installFolder = $config.installFolder
			}
			if ($config.solrPort) {
				$solrPort = $config.solrPort
			}
			if ($config.solrHost) {
				$solrHost = $config.solrHost
			}
			if ($config.solrSSL) {
				$solrSSL = $config.solrSSL
			}
			if ($config.nssmVersion) {
				$nssmVerion = $config.nssmVersion
			}
			if ($config.keystoreSecret) {
				$keystoreSecret = $config.keystoreSecret
			}
			if ($config.keystoreFile) {
				$KeystoreFile = $config.keystoreFile
			}
			if ($config.solrDomain) {
				$SolrDomain = $config.solrDomain
			}
			if ($config.maxJvmMem) {
				$maxJvmMem = $config.maxJvmMem
			}
			if ($config.clobber) {
				$Clobber = $config.clobber
			}
		}
	}

	$solrRoot = "$installFolder\$solrName"

	if (Test-Path $solrRoot) {
		if (!$Clobber) {
			$results = "$solrRoot already exists! Must use -Clobber to reinstall."
			Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
			return
		} else {
			Remove-Item $solrRoot -Recurse
		}
	}

	#if(!$downloadFolder) { $downloadFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("..\assets") }
	#if(!$downloadFolder) { $downloadFolder = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "assets" }
	#Write-Verbose "downloadFolder:$downloadFolder"
	#if (!(Test-Path $downloadFolder)){
#		New-Item -ItemType Directory -Path $downloadFolder
	#}

	## Verify elevated
	## https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
	$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
	if(!($elevated))
	{
		throw "In order to install services, please run this script elevated."
	}

	$JavaMinVersionRequired = "8.0.1510"
	if (Get-Module("JavaHelpers")) {
		Remove-Module "JavaHelpers"
	}
	Import-Module "$PSScriptRoot\JavaHelpers.psm1"

	$ErrorActionPreference = 'Stop'

	$JREVersion = ""
	$javaPath = "C:\Program Files\Java"
	if (Test-Path $javaPath) {
		$JREVersion = Get-ChildItem -Path $javaPath -name | Where-Object { -not $_.PsIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -first 1
	}
	if (!$JREVersion) {
		#choco install javaruntime

		$javaInstallPath = Join-Path $javaPath $JREVersion
		#$javaUrl = (Invoke-WebRequest -UseBasicParsing https://www.java.com/en/download/manual.jsp).Content | ForEach-Object{[regex]::matches($_, '(?:<a title="Download Java software for Windows \(64-bit\)" href=")(.*)(?:">)').Groups[1].Value} 
		$JDK_VER="7u75"
		$JDK_FULL_VER="7u75-b05"
		#$JDK_PATH="1.7.0_75"
		$javaUrl = "http://download.oracle.com/otn-pub/java/jdk/$JDK_FULL_VER/jdk-$JDK_VER-windows-x64.exe"
		#Java='https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244068_89d678f2be164786b292527658ca1605'

		$JDK_VER="8u202"
		$JDK_FULL_VER="8u202-b08"
		$JDK_PATH="1.8.0_60"
		$JDK_URL_PATH = "1961070e4c9b4e26a04e7f5a083f551e"		
		$javaUrl = "https://download.oracle.com/otn/java/jdk/$JDK_FULL_VER/$JDK_URL_PATH/jdk-$JDK_VER-windows-x64.exe"

		Write-Verbose "javaUrl:$javaUrl"
		Install-Tool java $javaUrl $javaInstallPath -packages $downloadFolder # would require creating Install-Java: -JavaMinVersionRequired $JavaMinVersionRequired
		if (Test-Path $javaPath) {
			$JREVersion = Get-ChildItem -Path $javaPath -name | Where-Object { -not $_.PsIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -first 1 -ErrorAction SilentlyContinue
		}
	}
	if (!$JREVersion) {
		Write-Error "$PSScriptName ERROR:Java not installed"
		exit 1
	}
	#Invoke-WebRequest -UseBasicParsing -OutFile jre8.exe $URL
	#Start-Process .\jre8.exe '/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0' -wait

	# Ensure Java environment variable
	try {
		$keytool = (Get-Command 'keytool.exe').Source
	} catch {
		$keytool = Get-JavaKeytool -JavaMinVersionRequired $JavaMinVersionRequired
	}

	if (!$keytool) {
		$jrePaths = @('C:\Program Files\Android\jdk\microsoft_dist_openjdk_1.8.0.25\bin')
		Write-Host "Checking all the paths..."
		foreach($jrePath in $jrePaths) {
			$testPath = Join-Path "$jrePath" 'keytool.exe'
			Write-Host "testPath:$testPath"
			if (Test-Path $testPath) {
				$keytool = (Get-Command $testPath).Source
			}
		}
	}

	if (!$keytool) {
		Write-Host "no keytool found";
		exit 1
	}
	#Write-Host "keytool:$keytool"

	# download & extract the solr archive to the right folder
	#$solrZip = "$downloadFolder\$solrName.zip"
	Install-Tool $solrPackage solr -path $solrRoot -packages $downloadFolder

	# download & extract the nssm archive to the right folder
	#$nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"
	Install-Tool $nssmPackage nssm -path $nssmRoot -packages $installFolder

	### PARAM VALIDATION
	if($keystoreSecret -ne 'secret') {
		Write-Error 'The keystore password must be "secret", because Solr apparently ignores the parameter'
	}

	if((Test-Path $KeystoreFile)) {
		if($Clobber) {
			Write-Host "Removing $KeystoreFile..."
			Remove-Item $KeystoreFile
		} else {
			$KeystorePath = Resolve-Path $KeystoreFile
			Write-Warning "Keystore file $KeystorePath already existed. To regenerate it, pass -Clobber."
		}
	}

	$P12Path = [IO.Path]::ChangeExtension($KeystoreFile, 'p12')
	if((Test-Path $P12Path)) {
		if($Clobber) {
			Write-Host "Removing $P12Path..."
			Remove-Item $P12Path
		} else {
			$P12Path = Resolve-Path $P12Path
			Write-Warning "Keystore file $P12Path already existed. To regenerate it, pass -Clobber."
		}
	}

	### DOING STUFF
	if(!(Test-Path $KeystoreFile)) {
		Write-Host ''
		Write-Host 'Generating JKS keystore...'
		& $keytool -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $keystoreSecret -storepass $keystoreSecret -validity 9999 -keystore $KeystoreFile -ext SAN=DNS:$SolrDomain,IP:127.0.0.1 -dname "CN=$SolrDomain, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"

		Write-Host ''
		Write-Host 'Generating .p12 to import to Windows...'
		& $keytool -importkeystore -srckeystore $KeystoreFile -destkeystore $P12Path -srcstoretype jks -deststoretype pkcs12 -srcstorepass $keystoreSecret -deststorepass $keystoreSecret

		Write-Host ''
		Write-Host 'Trusting generated SSL certificate...'
		$secureStringKeystorePassword = ConvertTo-SecureString -String $keystoreSecret -Force -AsPlainText
		$root = Import-PfxCertificate -FilePath $P12Path -Password $secureStringKeystorePassword -CertStoreLocation Cert:\LocalMachine\Root
		Write-Host 'SSL certificate is now locally trusted. (added as root CA)'

		if(-not $KeystoreFile.EndsWith('solr-ssl.keystore.jks')) {
			Write-Warning 'Your keystore file is not named "solr-ssl.keystore.jks"'
			Write-Warning 'Solr requires this exact name, so make sure to rename it before use.'
		}

		$KeystorePath = Resolve-Path $KeystoreFile
		Copy-Item $KeystorePath -Destination "$solrRoot\server\etc\solr-ssl.keystore.jks" -Force
	}

	# Update solr cfg to use keystore & right host name
	if(Test-Path -Path "$solrRoot\bin\solr.in.cmd.old")
	{
			Write-Host "Resetting solr.in.cmd" -ForegroundColor Green
			Remove-Item "$solrRoot\bin\solr.in.cmd"
			Rename-Item -Path "$solrRoot\bin\solr.in.cmd.old" -NewName "$solrRoot\bin\solr.in.cmd"
	}

	Write-Host "Rewriting solr config"

	$cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
	Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
	$certStorePath = "etc/solr-ssl.keystore.jks"
	$newCfg = $cfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStorePath" }
	$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$keystoreSecret" }
	$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStorePath" }
	$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$keystoreSecret" }
	$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
	$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_JAVA_MEM=-Xms512m -Xmx512m", "set SOLR_JAVA_MEM=-Xms512m -Xmx$maxJvmMem" }
	$newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"

	# install the service & runs
	$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
	if ($svc) {
		Write-Host "Solr service $solrName already exists..."
		if ($Clobber) {
			Write-Host "Removing Solr service"
			&"$installFolder\nssm-$nssmVersion\win64\nssm.exe" remove "$solrName"
			
			$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
		}
	}
	if(!($svc))
	{
		Write-Host "Installing Solr service:$solrName"
		&"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
		$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
	}

	if($svc.Status -ne "Running")
	{
		Write-Host "Starting Solr service:$($solrName):$solrPort..."
		Start-Service "$solrName"
	}
	elseif ($svc.Status -eq "Running")
	{
		Write-Host "Restarting Solr service$($solrName):$solrPort..."
		Restart-Service "$solrName"
	}

	Start-Sleep -s 5

	# finally prove it's all working
	$protocol = "http"
	if($solrSSL)
	{
		$protocol = "https"
	}

	Invoke-Expression "start $($protocol)://$($solrHost):$solrPort/solr/#/"

	# Resetting Progress Bar back to default
	$Global:ProgressPreference = "Continue"

	Write-Host ''
	Write-Host 'Done!' -InformationVariable results -ForegroundColor Green
	
	Write-Verbose (Get-Parameters $MyInvocation.MyCommand.Parameters $PSBoundParameters -Message "$($PSScriptName):$results" -Show -Stamp).output
}