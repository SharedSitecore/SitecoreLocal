Function Get-SitecoreDevCredentials {
	Param(
        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationFileName = "XP0-SitecoreLocal.json",
        
        # path if you want to use custom
        [Parameter(Mandatory=$false)]
        [string]$ConfigurationRoot = "",

		# installerVersion [default=]
		[Parameter(Mandatory=$false)]
		[string]$devSitecoreUserName = '',

		# Name of PSRepository [default=]
		[Parameter(Mandatory=$false)] [securestring]$devSitecorePassword,

        # Persist these settings - None, User, Machine Process [default=None]
		[Parameter(Mandatory=$false)]
		[ValidateSet('None','Machine','Process','User')]
		[string]$Persist = 'User'
	)
    try {
        if ($null -ne $global:loginSession -and $Persist -ne 'None') { Write-Host 'Already logged in' -ForegroundColor Green; return }
    } catch { }
    
    if ($Persist -eq 'None') {
        [Environment]::SetEnvironmentVariable("SITECORE_DEV_CREDS", $null, 'User')
        [Environment]::SetEnvironmentVariable("SITECORE_DEV_CREDS", $null, 'User')
        [Environment]::SetEnvironmentVariable("SITECORE_DEV_USER", $null, 'User')
        [Environment]::SetEnvironmentVariable("SITECORE_DEV_PWD", $null, 'User')
        $global:loginSession = $null
        $global:credentials = $null
    }

    $user = ''
    $password = ''
    $gotCreds = $false
    try {
        if ($null -ne $global:credentials) { return } # Already done .. $gotCreds = $true }
    } catch { }
    if (!$gotCreds -and $Persist -ne 'None') { $global:credentials = [Environment]::GetEnvironmentVariable("SITECORE_DEV_CREDS", $Persist); }
    if (!$gotCreds) {
        try {
            if ($Persist -ne 'None' -and [string]::IsNullOrEmpty($devSitecoreUserName)) {
                $devSitecoreUserName = [Environment]::GetEnvironmentVariable("SITECORE_DEV_USER", $Persist)
            }
            if ($Persist -ne 'None' -and [string]::IsNullOrEmpty($devSitecorePassword)) {
                $envPwd = [Environment]::GetEnvironmentVariable("SITECORE_DEV_PWD", $Persist)
                if ($envPwd) { $devSitecorePassword = $envPwd | ConvertTo-SecureString -AsPlainText -Force }
            }
    
            if ($Persist -eq 'None' -or [string]::IsNullOrEmpty($devSitecoreUserName)) {
                $global:credentials = Get-Credential -Message "Please provide dev.sitecore.com credentials"
            }
            elseif (![string]::IsNullOrEmpty($devSitecoreUserName) -and ![string]::IsNullOrEmpty($devSitecorePassword)) {
                #$secpasswd = ConvertTo-SecureString $devSitecorePassword -AsPlainText -Force
                $global:credentials = New-Object System.Management.Automation.PSCredential ($devSitecoreUserName, $devSitecorePassword)
                $gotCreds = $true
            }    
        }
        catch { }
    }
    
    #if ($null -eq $global:credentials) { starting throwing an error! cant use $global:credentials it hasnt been set?!@!
    if (!$gotCreds) {
        if ($Persist -ne 'None' -and [string]::IsNullOrEmpty($devSitecoreUserName)) {
			$devSitecoreUserName = [Environment]::GetEnvironmentVariable("SITECORE_DEV_USER", $Persist)
		}
        if ($Persist -ne 'None' -and [string]::IsNullOrEmpty($devSitecorePassword)) {
			$devSitecorePassword = [Environment]::GetEnvironmentVariable("SITECORE_DEV_PWD", $Persist)
		}
        if ($Persist -eq 'None' -or [string]::IsNullOrEmpty($devSitecoreUserName)) {
			$global:credentials = Get-Credential -Message "Please provide dev.sitecore.com credentials"
        }
        elseif (![string]::IsNullOrEmpty($devSitecoreUserName) -and ![string]::IsNullOrEmpty($devSitecorePassword)) {
            #$secpasswd = ConvertTo-SecureString $devSitecorePassword -AsPlainText -Force
            $global:credentials = New-Object System.Management.Automation.PSCredential ($devSitecoreUserName, $devSitecorePassword)
            $gotCreds = $true
        }
        else {
            throw "Credentials required for download - set them with -Persist"
        }
    }
    if ($null -ne $global:credentials) {
        $user = $global:credentials.GetNetworkCredential().UserName
        $password = $global:credentials.GetNetworkCredential().Password
    }
    Invoke-RestMethod -Uri https://dev.sitecore.net/api/authorization -Method Post -ContentType "application/json" -Body "{username: '$user', password: '$password'}" -SessionVariable loginSession -UseBasicParsing
    $global:loginSession = $loginSession

    if ($Persist -ne 'None') {
        [Environment]::SetEnvironmentVariable("SITECORE_LOGINS", $global:loginSession, $Persist)
                [Environment]::SetEnvironmentVariable("SITECORE_DEV_PWD", $password, $Persist)
    }
}