<#
.SYNOPSIS
  Applies enforced AppLocker rules and user-side blocks for games and launchers.
.DESCRIPTION
  Builds an enforced AppLocker policy (Exe/Script/Msi/Dll/Appx) that allows base
  OS and Program Files locations plus administrators, denies execution from
  user-writable locations (Downloads, Desktop, Temp, AppData), and blocks common
  game/launcher executables by name. Also adds user-side Store and DisallowRun
  blocks. Exports before/after evidence in the managed-workstation/user GPOs.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'

Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$ComputerGpoName = 'GPO-ManagedWorkstations-Security'
$UserGpoName = 'GPO-ManagedUsers-Restrictions'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-targeted-applocker-blocks-$Timestamp"
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

function New-PathRuleXml {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Description,
        [Parameter(Mandatory)] [string] $Sid,
        [Parameter(Mandatory)] [ValidateSet('Allow','Deny')] [string] $Action,
        [Parameter(Mandatory)] [string] $Path
    )
    return "    <FilePathRule Id=""$(New-Guid)"" Name=""$([Security.SecurityElement]::Escape($Name))"" Description=""$([Security.SecurityElement]::Escape($Description))"" UserOrGroupSid=""$Sid"" Action=""$Action""><Conditions><FilePathCondition Path=""$([Security.SecurityElement]::Escape($Path))"" /></Conditions></FilePathRule>"
}

function Add-DisallowRun {
    param(
        [string] $ValueName,
        [string] $Executable
    )
    Set-GPRegistryValue -Name $UserGpoName -Domain $Domain -Server $GpoServer `
        -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun' `
        -ValueName $ValueName -Type String -Value $Executable | Out-Null
}

Get-GPOReport -Name $ComputerGpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'workstations-before.html')
Get-GPOReport -Name $ComputerGpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'workstations-before.xml')
Get-GPOReport -Name $UserGpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'users-before.html')
Get-GPOReport -Name $UserGpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'users-before.xml')

$everyoneSid = 'S-1-1-0'
$adminSid = 'S-1-5-32-544'

$exeRules = New-Object System.Collections.Generic.List[string]
$scriptRules = New-Object System.Collections.Generic.List[string]
$msiRules = New-Object System.Collections.Generic.List[string]
$dllRules = New-Object System.Collections.Generic.List[string]
$appxRules = New-Object System.Collections.Generic.List[string]

# Allow base OS/app locations and administrators. Deny rules below take precedence.
foreach ($path in @('%WINDIR%\*', '%PROGRAMFILES%\*', '%PROGRAMFILES% (x86)\*')) {
    $exeRules.Add((New-PathRuleXml "Allow Everyone $path executables" 'Base allow rule.' $everyoneSid Allow $path)) | Out-Null
    $scriptRules.Add((New-PathRuleXml "Allow Everyone $path scripts" 'Base allow rule.' $everyoneSid Allow $path)) | Out-Null
    $msiRules.Add((New-PathRuleXml "Allow Everyone $path installers" 'Base allow rule.' $everyoneSid Allow $path)) | Out-Null
    $dllRules.Add((New-PathRuleXml "Allow Everyone $path DLLs" 'Base allow rule.' $everyoneSid Allow $path)) | Out-Null
}
foreach ($collection in @($exeRules, $scriptRules, $msiRules, $dllRules)) {
    $collection.Add((New-PathRuleXml 'Allow Administrators all' 'Administrators bypass AppLocker targeted blocks.' $adminSid Allow '*')) | Out-Null
}

$blockedUserPaths = @(
    '%OSDRIVE%\Users\*\Downloads\*',
    '%OSDRIVE%\Users\*\Desktop\*',
    '%OSDRIVE%\Users\*\AppData\Local\Temp\*',
    '%OSDRIVE%\Users\*\AppData\Local\Programs\*',
    '%OSDRIVE%\Users\*\AppData\Local\Roblox\*',
    '%OSDRIVE%\Users\*\AppData\Roaming\Roblox\*',
    '%OSDRIVE%\Users\*\AppData\Local\Steam\*',
    '%OSDRIVE%\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Steam\*',
    '%OSDRIVE%\Users\*\OneDrive\Downloads\*',
    '%OSDRIVE%\Users\*\OneDrive\Desktop\*'
)

foreach ($path in $blockedUserPaths) {
    $exeRules.Add((New-PathRuleXml "Deny user-writable executables $path" 'Blocks launching downloaded or per-user executables.' $everyoneSid Deny $path)) | Out-Null
    $scriptRules.Add((New-PathRuleXml "Deny user-writable scripts $path" 'Blocks launching downloaded or per-user scripts.' $everyoneSid Deny $path)) | Out-Null
    $msiRules.Add((New-PathRuleXml "Deny user-writable installers $path" 'Blocks launching downloaded or per-user installers.' $everyoneSid Deny $path)) | Out-Null
    $dllRules.Add((New-PathRuleXml "Deny user-writable DLLs $path" 'Blocks loading DLLs from downloaded or per-user locations.' $everyoneSid Deny $path)) | Out-Null
}

$blockedNames = @(
    'RobloxPlayerBeta.exe',
    'RobloxPlayerInstaller.exe',
    'RobloxStudioInstaller.exe',
    'RobloxStudioBeta.exe',
    'Steam.exe',
    'steamwebhelper.exe',
    'EpicGamesLauncher.exe',
    'FortniteClient-Win64-Shipping.exe',
    'MinecraftLauncher.exe',
    'RiotClientServices.exe',
    'Battle.net.exe',
    'XboxPcApp.exe',
    'GameBar.exe',
    'GameBarFTServer.exe'
)

foreach ($name in $blockedNames) {
    $exeRules.Add((New-PathRuleXml "Deny $name" 'Blocks common game or game-launcher executable names.' $everyoneSid Deny "*\$name")) | Out-Null
}

$appxRules.Add('    <FilePublisherRule Id="' + (New-Guid) + '" Name="Allow signed packaged apps" Description="Default packaged app allow rule; Store/Xbox access is separately blocked by user policy." UserOrGroupSid="' + $everyoneSid + '" Action="Allow"><Conditions><FilePublisherCondition PublisherName="*" ProductName="*" BinaryName="*"><BinaryVersionRange LowSection="0.0.0.0" HighSection="*" /></FilePublisherCondition></Conditions></FilePublisherRule>') | Out-Null

$policy = @"
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="Enabled">
$($exeRules -join "`r`n")
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="Enabled">
$($scriptRules -join "`r`n")
  </RuleCollection>
  <RuleCollection Type="Msi" EnforcementMode="Enabled">
$($msiRules -join "`r`n")
  </RuleCollection>
  <RuleCollection Type="Dll" EnforcementMode="Enabled">
$($dllRules -join "`r`n")
  </RuleCollection>
  <RuleCollection Type="Appx" EnforcementMode="Enabled">
$($appxRules -join "`r`n")
  </RuleCollection>
</AppLockerPolicy>
"@

$policyPath = Join-Path $EvidenceRoot 'targeted-applocker-policy.xml'
Set-Content -LiteralPath $policyPath -Value $policy -Encoding UTF8

$computerGpo = Get-GPO -Name $ComputerGpoName -Domain $Domain -Server $GpoServer
$ldap = "LDAP://CN={$($computerGpo.Id)},CN=Policies,CN=System,DC=corp,DC=local"
Set-AppLockerPolicy -XMLPolicy $policyPath -LDAP $ldap

# User-side Store/Xbox/game launcher blocks.
Set-GPRegistryValue -Name $UserGpoName -Domain $Domain -Server $GpoServer `
    -Key 'HKCU\Software\Policies\Microsoft\WindowsStore' -ValueName 'RemoveWindowsStore' -Type DWord -Value 1 | Out-Null
Set-GPRegistryValue -Name $UserGpoName -Domain $Domain -Server $GpoServer `
    -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName 'DisallowRun' -Type DWord -Value 1 | Out-Null

$startIndex = 20
foreach ($name in $blockedNames) {
    Add-DisallowRun -ValueName ([string]$startIndex) -Executable $name
    $startIndex++
}

Get-GPOReport -Name $ComputerGpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'workstations-after.html')
Get-GPOReport -Name $ComputerGpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'workstations-after.xml')
Get-GPOReport -Name $UserGpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $EvidenceRoot 'users-after.html')
Get-GPOReport -Name $UserGpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $EvidenceRoot 'users-after.xml')

Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    ComputerGpo = $ComputerGpoName
    UserGpo = $UserGpoName
    Evidence = "$EvidenceRoot.zip"
    BlockedUserPaths = $blockedUserPaths
    BlockedNames = $blockedNames
} | ConvertTo-Json -Depth 5
