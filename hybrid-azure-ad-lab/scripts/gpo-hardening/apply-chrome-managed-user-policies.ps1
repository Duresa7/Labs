<#
.SYNOPSIS
  Applies per-user Google Chrome policy for managed users in corp.local.
.DESCRIPTION
  Sets HKCU Chrome policies in the managed-users GPO: forces SafeSearch and
  YouTube restricted mode, disables sync/guest/incognito, locks extensions to an
  approved allowlist with force-install, and seeds a URL blocklist for games,
  game launchers, and common distraction sites. Exports before/after evidence.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'

Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$GpoName = 'GPO-ManagedUsers-Restrictions'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-chrome-managed-user-policies-$Timestamp"
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

function Set-ChromePolicy {
    param(
        [Parameter(Mandatory)] [string] $Key,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [ValidateSet('DWord','String')] [string] $Type,
        [Parameter(Mandatory)] $Value
    )
    try {
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    } catch {
        Start-Sleep -Seconds 2
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    }
}

function Set-ListPolicy {
    param(
        [Parameter(Mandatory)] [string] $SubKey,
        [Parameter(Mandatory)] [string[]] $Values
    )
    $key = "HKCU\Software\Policies\Google\Chrome\$SubKey"
    $i = 1
    foreach ($value in $Values) {
        Set-ChromePolicy -Key $key -Name ([string]$i) -Type String -Value $value
        $i++
    }
}

Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'before.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'before.xml')

$chromeKey = 'HKCU\Software\Policies\Google\Chrome'

# Core browser restrictions. Browser sign-in remains allowed for personal Gmail use; Chrome Sync is disabled.
Set-ChromePolicy -Key $chromeKey -Name 'BrowserSignin' -Type DWord -Value 1
Set-ChromePolicy -Key $chromeKey -Name 'SyncDisabled' -Type DWord -Value 1
Set-ChromePolicy -Key $chromeKey -Name 'IncognitoModeAvailability' -Type DWord -Value 1
Set-ChromePolicy -Key $chromeKey -Name 'BrowserGuestModeEnabled' -Type DWord -Value 0
Set-ChromePolicy -Key $chromeKey -Name 'BrowserAddPersonEnabled' -Type DWord -Value 0
Set-ChromePolicy -Key $chromeKey -Name 'ForceGoogleSafeSearch' -Type DWord -Value 1
Set-ChromePolicy -Key $chromeKey -Name 'ForceYouTubeRestrict' -Type DWord -Value 2

# Extension lockdown: block every extension except the two approved ones, and force-install both.
$ublockLite = 'ddkjiahejlhfcafbddmgiahcphecmpfh'
$googleDocsOffline = 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
$updateUrl = 'https://clients2.google.com/service/update2/crx'
Set-ListPolicy -SubKey 'ExtensionInstallBlocklist' -Values @('*')
Set-ListPolicy -SubKey 'ExtensionInstallAllowlist' -Values @($ublockLite, $googleDocsOffline)
Set-ListPolicy -SubKey 'ExtensionInstallForcelist' -Values @("$ublockLite;$updateUrl", "$googleDocsOffline;$updateUrl")

# First-pass site blocks for games, game launchers, and common bypass/distraction services.
$blockedUrls = @(
    '*://roblox.com/*',
    '*://*.roblox.com/*',
    '*://steampowered.com/*',
    '*://*.steampowered.com/*',
    '*://steamcommunity.com/*',
    '*://*.steamcommunity.com/*',
    '*://store.steampowered.com/*',
    '*://epicgames.com/*',
    '*://*.epicgames.com/*',
    '*://fortnite.com/*',
    '*://*.fortnite.com/*',
    '*://minecraft.net/*',
    '*://*.minecraft.net/*',
    '*://xbox.com/play*',
    '*://www.xbox.com/*/play*',
    '*://discord.com/*',
    '*://*.discord.com/*',
    '*://discordapp.com/*',
    '*://*.discordapp.com/*',
    '*://twitch.tv/*',
    '*://*.twitch.tv/*',
    '*://battle.net/*',
    '*://*.battle.net/*',
    '*://riotgames.com/*',
    '*://*.riotgames.com/*',
    '*://leagueoflegends.com/*',
    '*://*.leagueoflegends.com/*'
)
Set-ListPolicy -SubKey 'URLBlocklist' -Values $blockedUrls

Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'after.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'after.xml')

Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    Gpo = $GpoName
    Evidence = "$EvidenceRoot.zip"
    ExtensionInstallBlocklist = '*'
    ExtensionInstallAllowlist = @(
        [pscustomobject]@{Name='uBlock Origin Lite';Id=$ublockLite},
        [pscustomobject]@{Name='Google Docs Offline';Id=$googleDocsOffline}
    )
    ForcedExtensions = @('uBlock Origin Lite','Google Docs Offline')
    UrlBlocklistCount = $blockedUrls.Count
} | ConvertTo-Json -Depth 5
