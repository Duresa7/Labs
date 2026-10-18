<#
.SYNOPSIS
  Applies machine-wide Google Chrome policy on managed workstations in corp.local.
.DESCRIPTION
  Sets HKLM Chrome policies in the managed-workstation GPO: forces SafeSearch and
  YouTube restricted mode, disables sync/guest/incognito, locks extensions to an
  approved allowlist with force-install, and seeds a URL blocklist for games and
  game launchers. Exports before/after GPO evidence.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'
Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$GpoName = 'GPO-ManagedWorkstations-Security'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-chrome-machine-policies-$Timestamp"
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

function Set-Policy {
    param([string]$Key, [string]$Name, [ValidateSet('DWord','String')] [string]$Type, $Value)
    try {
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    } catch {
        Start-Sleep -Seconds 2
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    }
}

function Set-List {
    param([string]$SubKey, [string[]]$Values)
    $key = "HKLM\Software\Policies\Google\Chrome\$SubKey"
    for ($i = 0; $i -lt $Values.Count; $i++) {
        Set-Policy -Key $key -Name ([string]($i + 1)) -Type String -Value $Values[$i]
    }
}

Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'before.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'before.xml')

$chromeKey = 'HKLM\Software\Policies\Google\Chrome'
Set-Policy $chromeKey 'BrowserSignin' DWord 1
Set-Policy $chromeKey 'SyncDisabled' DWord 1
Set-Policy $chromeKey 'IncognitoModeAvailability' DWord 1
Set-Policy $chromeKey 'BrowserGuestModeEnabled' DWord 0
Set-Policy $chromeKey 'BrowserAddPersonEnabled' DWord 0
Set-Policy $chromeKey 'ForceGoogleSafeSearch' DWord 1
Set-Policy $chromeKey 'ForceYouTubeRestrict' DWord 2

$ublockLite = 'ddkjiahejlhfcafbddmgiahcphecmpfh'
$googleDocsOffline = 'ghbmnnjooekpmoecnnnilnnbdlolhkhi'
$updateUrl = 'https://clients2.google.com/service/update2/crx'
Set-List 'ExtensionInstallBlocklist' @('*')
Set-List 'ExtensionInstallAllowlist' @($ublockLite, $googleDocsOffline)
Set-List 'ExtensionInstallForcelist' @("$ublockLite;$updateUrl", "$googleDocsOffline;$updateUrl")

$blockedUrls = @(
    'roblox.com',
    '*.roblox.com',
    'steampowered.com',
    '*.steampowered.com',
    'store.steampowered.com',
    'steamcommunity.com',
    '*.steamcommunity.com',
    'epicgames.com',
    '*.epicgames.com',
    'fortnite.com',
    '*.fortnite.com',
    'minecraft.net',
    '*.minecraft.net',
    'xbox.com/play*',
    'www.xbox.com/*/play*',
    'discord.com',
    '*.discord.com',
    'discordapp.com',
    '*.discordapp.com',
    'twitch.tv',
    '*.twitch.tv',
    'battle.net',
    '*.battle.net',
    'riotgames.com',
    '*.riotgames.com',
    'leagueoflegends.com',
    '*.leagueoflegends.com',
    '*://roblox.com/*',
    '*://*.roblox.com/*',
    '*://steampowered.com/*',
    '*://*.steampowered.com/*',
    '*://store.steampowered.com/*',
    '*://steamcommunity.com/*',
    '*://*.steamcommunity.com/*'
)
Set-List 'URLBlocklist' $blockedUrls

Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'after.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'after.xml')
Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    Gpo = $GpoName
    Scope = 'Machine'
    Evidence = "$EvidenceRoot.zip"
    UrlBlocklistCount = $blockedUrls.Count
} | ConvertTo-Json -Depth 4
