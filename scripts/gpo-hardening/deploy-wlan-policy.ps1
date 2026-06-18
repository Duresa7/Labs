<#
.SYNOPSIS
  Deploys a machine startup script that enforces a single allowed Wi-Fi profile.
.DESCRIPTION
  Writes a WPA2-PSK WLAN profile for the approved SSID into the managed-workstation
  GPO as a machine startup script, configures WlanSvc, adds the profile for all
  users, and applies netsh WLAN filters that allow only the approved SSID and deny
  all other infrastructure/adhoc networks. Bumps the GPT.INI version and exports
  before/after evidence. The Wi-Fi pre-shared key is supplied at runtime.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded.
#>
param([string]$WifiPsk = 'REPLACE-WITH-WIFI-PSK')

$ErrorActionPreference = 'Stop'

Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$GpoName = 'GPO-ManagedWorkstations-Security'
$Ssid = 'CorpLab-WiFi'
$WifiPassword = $WifiPsk
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-wlan-policy-$Timestamp"
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

$gpo = Get-GPO -Name $GpoName -Domain $Domain -Server $GpoServer
$gpoGuid = $gpo.Id.ToString('B').ToUpperInvariant()
$policyRoot = "\\$Domain\SYSVOL\$Domain\Policies\$gpoGuid"
$startupDir = Join-Path $policyRoot 'Machine\Scripts\Startup'
$scriptName = 'corp-enforce-wlan-policy.ps1'
$cmdName = 'corp-enforce-wlan-policy.cmd'
$psScriptPath = Join-Path $startupDir $scriptName
$cmdPath = Join-Path $startupDir $cmdName
$scriptsIniPath = Join-Path $startupDir 'scripts.ini'
$gptIniPath = Join-Path $policyRoot 'GPT.INI'

New-Item -ItemType Directory -Path $startupDir -Force | Out-Null

Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'before.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'before.xml')
if (Test-Path $scriptsIniPath) {
    Copy-Item -LiteralPath $scriptsIniPath -Destination (Join-Path $EvidenceRoot 'scripts-before.ini') -Force
}
Copy-Item -LiteralPath $gptIniPath -Destination (Join-Path $EvidenceRoot 'GPT-before.INI') -Force

$profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>$Ssid</name>
  <SSIDConfig>
    <SSID>
      <name>$Ssid</name>
    </SSID>
  </SSIDConfig>
  <connectionType>ESS</connectionType>
  <connectionMode>auto</connectionMode>
  <MSM>
    <security>
      <authEncryption>
        <authentication>WPA2PSK</authentication>
        <encryption>AES</encryption>
        <useOneX>false</useOneX>
      </authEncryption>
      <sharedKey>
        <keyType>passPhrase</keyType>
        <protected>false</protected>
        <keyMaterial>$WifiPassword</keyMaterial>
      </sharedKey>
    </security>
  </MSM>
</WLANProfile>
"@

$startupScript = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$ssid = '$Ssid'
`$profilePath = Join-Path `$env:ProgramData 'CORP\Wireless\CorpLab-WiFi.xml'
New-Item -ItemType Directory -Path (Split-Path -Parent `$profilePath) -Force | Out-Null
@'
$profileXml
'@ | Set-Content -LiteralPath `$profilePath -Encoding UTF8 -Force

`$wlan = Get-Service WlanSvc -ErrorAction SilentlyContinue
if (`$wlan) {
    Set-Service WlanSvc -StartupType Automatic
    Start-Service WlanSvc

    netsh wlan add profile filename="`$profilePath" user=all | Out-Null
    netsh wlan set profileparameter name="`$ssid" connectionmode=auto | Out-Null

    netsh wlan add filter permission=allow ssid="`$ssid" networktype=infrastructure | Out-Null
    netsh wlan add filter permission=denyall networktype=infrastructure | Out-Null
    netsh wlan add filter permission=denyall networktype=adhoc | Out-Null
}
"@

$cmd = '@echo off' + "`r`n" + 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0corp-enforce-wlan-policy.ps1"' + "`r`n"

Set-Content -LiteralPath $psScriptPath -Value $startupScript -Encoding UTF8
Set-Content -LiteralPath $cmdPath -Value $cmd -Encoding ASCII

$scriptsIni = @"
[Startup]
0CmdLine=$cmdName
0Parameters=
"@
Set-Content -LiteralPath $scriptsIniPath -Value $scriptsIni -Encoding Unicode

$gpt = Get-Content -LiteralPath $gptIniPath
$versionLineIndex = -1
for ($i = 0; $i -lt $gpt.Count; $i++) {
    if ($gpt[$i] -match '^Version=(\d+)$') {
        $versionLineIndex = $i
        break
    }
}
if ($versionLineIndex -lt 0) {
    $gpt += 'Version=1'
} else {
    $version = [int]($gpt[$versionLineIndex] -replace '^Version=', '')
    $machineVersion = [math]::Floor($version / 65536)
    $userVersion = $version % 65536
    $machineVersion++
    $gpt[$versionLineIndex] = 'Version=' + (($machineVersion * 65536) + $userVersion)
}
Set-Content -LiteralPath $gptIniPath -Value $gpt -Encoding ASCII

Copy-Item -LiteralPath $scriptsIniPath -Destination (Join-Path $EvidenceRoot 'scripts-after.ini') -Force
Copy-Item -LiteralPath $gptIniPath -Destination (Join-Path $EvidenceRoot 'GPT-after.INI') -Force
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'after.html')
Get-GPOReport -Name $GpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'after.xml')

Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    Gpo = $GpoName
    Ssid = $Ssid
    StartupScript = $psScriptPath
    Evidence = "$EvidenceRoot.zip"
} | ConvertTo-Json -Depth 4
