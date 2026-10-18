<#
.SYNOPSIS
  Applies baseline GPO hardening for managed users and workstations in corp.local.
.DESCRIPTION
  Configures two Group Policy Objects (managed-user restrictions and
  managed-workstation security): user-side lockdowns (Run dialog, PowerShell,
  MMC, network UI), machine-side protections (WDigest, LSA PPL, USB storage,
  AutoRun), a security template restricting local Administrators, and an
  AppLocker audit-mode baseline. Exports before/after evidence and a report.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'

Import-Module GroupPolicy
Import-Module ActiveDirectory
Import-Module AppLocker

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$UserGpoName = 'GPO-ManagedUsers-Restrictions'
$ComputerGpoName = 'GPO-ManagedWorkstations-Security'
$UserTargetOu = 'OU=Managed,OU=Users-Accounts,DC=corp,DC=local'
$ComputerTargetOu = 'OU=Managed,OU=Workstations,DC=corp,DC=local'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ExportRoot = "C:\Windows\Temp\corp-gpo-hardening-$Timestamp"
$ReportPath = Join-Path $ExportRoot "CORP-GPO-Hardening-Report-$Timestamp.md"
New-Item -ItemType Directory -Path $ExportRoot -Force | Out-Null

$Changes = New-Object System.Collections.Generic.List[string]
$Validation = New-Object System.Collections.Generic.List[string]

function Add-Change {
    param([string]$Text)
    $Changes.Add($Text) | Out-Null
}

function Add-Validation {
    param([string]$Text)
    $Validation.Add($Text) | Out-Null
}

function Set-GpoReg {
    param(
        [Parameter(Mandatory)] [string] $GpoName,
        [Parameter(Mandatory)] [string] $Key,
        [Parameter(Mandatory)] [string] $ValueName,
        [Parameter(Mandatory)] $Value,
        [Parameter(Mandatory)] [ValidateSet('DWord','String','ExpandString','MultiString','QWord','Binary')] [string] $Type,
        [Parameter(Mandatory)] [string] $Description
    )

    try {
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $ValueName -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    } catch {
        Start-Sleep -Seconds 2
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $ValueName -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    }
    Add-Change "${GpoName}: $Description ($Key\$ValueName = $Value)"
}

function Export-GpoReportPair {
    param(
        [Parameter(Mandatory)] [string] $Phase
    )

    $phaseDir = Join-Path $ExportRoot $Phase
    New-Item -ItemType Directory -Path $phaseDir -Force | Out-Null
    foreach ($gpoName in @($UserGpoName, $ComputerGpoName)) {
        $safeName = $gpoName -replace '[^\w.-]', '_'
        Get-GPOReport -Name $gpoName -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $phaseDir "$safeName.html")
        Get-GPOReport -Name $gpoName -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $phaseDir "$safeName.xml")
    }
}

function Ensure-GpoLinked {
    param(
        [Parameter(Mandatory)] [string] $GpoName,
        [Parameter(Mandatory)] [string] $TargetOu
    )

    $gpo = Get-GPO -Name $GpoName -Domain $Domain -Server $GpoServer
    $ou = Get-ADOrganizationalUnit -Identity $TargetOu -Properties gPLink
    if ($ou.gPLink -notmatch [regex]::Escape($gpo.Id.ToString())) {
        throw "Expected $GpoName ($($gpo.Id)) to be linked to $TargetOu, but gPLink is: $($ou.gPLink)"
    }
    Add-Validation "Confirmed $GpoName is linked to $TargetOu."
}

function Set-IniSectionKey {
    param(
        [Parameter(Mandatory)] [ref] $Lines,
        [Parameter(Mandatory)] [string] $Section,
        [Parameter(Mandatory)] [string] $Key,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Value
    )

    $list = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines.Value) { $list.Add($line) | Out-Null }

    $sectionIndex = -1
    for ($i = 0; $i -lt $list.Count; $i++) {
        if ($list[$i] -eq "[$Section]") {
            $sectionIndex = $i
            break
        }
    }

    if ($sectionIndex -lt 0) {
        if ($list.Count -gt 0 -and $list[$list.Count - 1].Trim() -ne '') { $list.Add('') | Out-Null }
        $list.Add("[$Section]") | Out-Null
        $list.Add("$Key = $Value") | Out-Null
        $Lines.Value = $list.ToArray()
        return
    }

    $nextSectionIndex = $list.Count
    for ($i = $sectionIndex + 1; $i -lt $list.Count; $i++) {
        if ($list[$i] -match '^\[.+\]$') {
            $nextSectionIndex = $i
            break
        }
    }

    for ($i = $sectionIndex + 1; $i -lt $nextSectionIndex; $i++) {
        if ($list[$i] -match "^\s*$([regex]::Escape($Key))\s*=") {
            $list[$i] = "$Key = $Value"
            $Lines.Value = $list.ToArray()
            return
        }
    }

    $list.Insert($nextSectionIndex, "$Key = $Value")
    $Lines.Value = $list.ToArray()
}

function Update-SecurityTemplate {
    param(
        [Parameter(Mandatory)] [string] $GpoName
    )

    $gpo = Get-GPO -Name $GpoName -Domain $Domain -Server $GpoServer
    $gpoGuid = $gpo.Id.ToString()
    $gptTmplPath = "\\$Domain\SYSVOL\$Domain\Policies\{$gpoGuid}\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"
    $gptTmplDir = Split-Path -Parent $gptTmplPath
    New-Item -ItemType Directory -Path $gptTmplDir -Force | Out-Null

    if (Test-Path $gptTmplPath) {
        Copy-Item -LiteralPath $gptTmplPath -Destination (Join-Path $ExportRoot "GptTmpl-before-$Timestamp.inf") -Force
        $lines = @(Get-Content -LiteralPath $gptTmplPath)
    } else {
        $lines = @('[Unicode]', 'Unicode=yes', '[Version]', 'signature="$CHICAGO$"', 'Revision=1')
    }

    $domainAdmins = Get-ADGroup -Identity 'Domain Admins'
    $domainAdminsSid = "*$($domainAdmins.SID.Value)"
    $builtinAdminsSid = '*S-1-5-32-544'
    $localServiceSid = '*S-1-5-19'

    $lineRef = [ref] $lines
    Set-IniSectionKey -Lines $lineRef -Section 'Group Membership' -Key "$builtinAdminsSid`__Memberof" -Value ''
    Set-IniSectionKey -Lines $lineRef -Section 'Group Membership' -Key "$builtinAdminsSid`__Members" -Value $domainAdminsSid
    Set-IniSectionKey -Lines $lineRef -Section 'System Access' -Key 'EnableAdminAccount' -Value '0'
    Set-IniSectionKey -Lines $lineRef -Section 'Privilege Rights' -Key 'SeSystemtimePrivilege' -Value "$builtinAdminsSid,$localServiceSid"
    $lines = $lineRef.Value

    Set-Content -LiteralPath $gptTmplPath -Value $lines -Encoding Unicode
    Copy-Item -LiteralPath $gptTmplPath -Destination (Join-Path $ExportRoot "GptTmpl-after-$Timestamp.inf") -Force

    Add-Change "${GpoName}: Restricted local Administrators membership to CORP\Domain Admins."
    Add-Change "${GpoName}: Disabled the built-in local Administrator account through security policy."
    Add-Change "${GpoName}: Restricted Change system time right to local Administrators and LOCAL SERVICE."
}

function Configure-AppLockerAuditPolicy {
    param(
        [Parameter(Mandatory)] [string] $GpoName
    )

    $gpo = Get-GPO -Name $GpoName -Domain $Domain -Server $GpoServer
    $ldap = "LDAP://CN={$($gpo.Id)},CN=Policies,CN=System,DC=corp,DC=local"
    $xmlPath = Join-Path $ExportRoot "AppLocker-audit-policy-$Timestamp.xml"
    $adminSid = 'S-1-5-32-544'
    $everyoneSid = 'S-1-1-0'

    [xml] $xml = @"
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="AuditOnly">
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Windows executables" Description="Default audit allow rule for Windows executables." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%WINDIR%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Program Files executables" Description="Default audit allow rule for Program Files executables." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Administrators all executables" Description="Default audit allow rule for local administrators." UserOrGroupSid="$adminSid" Action="Allow"><Conditions><FilePathCondition Path="*" /></Conditions></FilePathRule>
  </RuleCollection>
  <RuleCollection Type="Script" EnforcementMode="AuditOnly">
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Windows scripts" Description="Default audit allow rule for Windows scripts." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%WINDIR%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Program Files scripts" Description="Default audit allow rule for Program Files scripts." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Administrators all scripts" Description="Default audit allow rule for local administrators." UserOrGroupSid="$adminSid" Action="Allow"><Conditions><FilePathCondition Path="*" /></Conditions></FilePathRule>
  </RuleCollection>
  <RuleCollection Type="Msi" EnforcementMode="AuditOnly">
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Windows Installer cache" Description="Default audit allow rule for Windows Installer cache." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%WINDIR%\Installer\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Program Files installers" Description="Default audit allow rule for Program Files installers." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Administrators all installers" Description="Default audit allow rule for local administrators." UserOrGroupSid="$adminSid" Action="Allow"><Conditions><FilePathCondition Path="*" /></Conditions></FilePathRule>
  </RuleCollection>
  <RuleCollection Type="Dll" EnforcementMode="AuditOnly">
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Windows DLLs" Description="Default audit allow rule for Windows DLLs." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%WINDIR%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Everyone Program Files DLLs" Description="Default audit allow rule for Program Files DLLs." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePathCondition Path="%PROGRAMFILES%\*" /></Conditions></FilePathRule>
    <FilePathRule Id="$(New-Guid)" Name="Allow Administrators all DLLs" Description="Default audit allow rule for local administrators." UserOrGroupSid="$adminSid" Action="Allow"><Conditions><FilePathCondition Path="*" /></Conditions></FilePathRule>
  </RuleCollection>
  <RuleCollection Type="Appx" EnforcementMode="AuditOnly">
    <FilePublisherRule Id="$(New-Guid)" Name="Allow Everyone signed packaged apps" Description="Default audit allow rule for signed packaged apps." UserOrGroupSid="$everyoneSid" Action="Allow"><Conditions><FilePublisherCondition PublisherName="*" ProductName="*" BinaryName="*"><BinaryVersionRange LowSection="0.0.0.0" HighSection="*" /></FilePublisherCondition></Conditions></FilePublisherRule>
  </RuleCollection>
</AppLockerPolicy>
"@
    $xml.Save($xmlPath)
    Set-AppLockerPolicy -XMLPolicy $xmlPath -LDAP $ldap

    Add-Change "${GpoName}: Configured AppLocker default allow rules for Windows and Program Files in audit mode."
    Add-Change "${GpoName}: Included AppLocker rule collections: Exe, Script, Msi, Dll, Appx."
}

Ensure-GpoLinked -GpoName $UserGpoName -TargetOu $UserTargetOu
Ensure-GpoLinked -GpoName $ComputerGpoName -TargetOu $ComputerTargetOu
Export-GpoReportPair -Phase 'before'

# User-side policy settings.
$userExplorer = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
$userSystem = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$userActiveDesktop = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop'
$userInstaller = 'HKCU\Software\Policies\Microsoft\Windows\Installer'
$userPowerShell = 'HKCU\Software\Policies\Microsoft\Windows\PowerShell'
$userMmc = 'HKCU\Software\Policies\Microsoft\MMC'
$userNetworkConnections = 'HKCU\Software\Policies\Microsoft\Windows\Network Connections'

Set-GpoReg $UserGpoName $userExplorer 'NoRun' 1 DWord 'Disabled the Run dialog'
Set-GpoReg $UserGpoName $userExplorer 'DisallowRun' 1 DWord 'Enabled Explorer application launch deny list'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '1' 'powershell.exe' String 'Blocked Windows PowerShell'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '2' 'powershell_ise.exe' String 'Blocked Windows PowerShell ISE'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '3' 'pwsh.exe' String 'Blocked PowerShell 7'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '4' 'mmc.exe' String 'Blocked Microsoft Management Console'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '5' 'msconfig.exe' String 'Blocked System Configuration'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '6' 'control.exe' String 'Blocked Control Panel launcher'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '7' 'gpedit.msc' String 'Blocked Local Group Policy Editor launch by file association'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '8' 'secpol.msc' String 'Blocked Local Security Policy launch by file association'
Set-GpoReg $UserGpoName "$userExplorer\DisallowRun" '9' 'lusrmgr.msc' String 'Blocked Local Users and Groups launch by file association'
Set-GpoReg $UserGpoName $userExplorer 'SettingsPageVisibility' 'showonly:display;project' String 'Restricted Windows Settings to Display and Project pages to preserve multi-monitor workflows'
Set-GpoReg $UserGpoName $userSystem 'DisableChangePassword' 1 DWord 'Removed access to change-password UI'
Set-GpoReg $UserGpoName $userActiveDesktop 'NoChangingWallPaper' 1 DWord 'Prevented wallpaper changes'
Set-GpoReg $UserGpoName $userSystem 'NoDispAppearancePage' 1 DWord 'Blocked appearance/personalization display page'
Set-GpoReg $UserGpoName $userSystem 'NoDispBackgroundPage' 1 DWord 'Blocked desktop background page'
Set-GpoReg $UserGpoName $userSystem 'NoDispScrSavPage' 1 DWord 'Blocked screen saver page'
Set-GpoReg $UserGpoName $userInstaller 'AlwaysInstallElevated' 0 DWord 'Disabled Always install with elevated privileges for users'
Set-GpoReg $UserGpoName $userPowerShell 'EnableScripts' 0 DWord 'Disabled PowerShell script execution by policy'
Set-GpoReg $UserGpoName $userMmc 'RestrictToPermittedSnapins' 1 DWord 'Restricted MMC to permitted snap-ins; no snap-ins are permitted in this GPO'
Set-GpoReg $UserGpoName $userNetworkConnections 'NC_LanProperties' 0 DWord 'Prevented access to LAN connection properties'
Set-GpoReg $UserGpoName $userNetworkConnections 'NC_AdvancedSettings' 0 DWord 'Prevented advanced network adapter configuration'
Set-GpoReg $UserGpoName $userNetworkConnections 'NC_AllowNetBridge_NLA' 0 DWord 'Prevented network bridge creation'
Set-GpoReg $UserGpoName $userNetworkConnections 'NC_ShowSharedAccessUI' 0 DWord 'Hid shared access network configuration UI'
Set-GpoReg $UserGpoName $userNetworkConnections 'NC_EnableAdminProhibits' 1 DWord 'Enabled network connection prohibitions for administrators to enforce policy'

# Computer-side registry policy settings.
$machineInstaller = 'HKLM\Software\Policies\Microsoft\Windows\Installer'
$machineExplorer = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
$machineWinlogon = 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
$machineWDigest = 'HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest'
$machineLsa = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'
$machineUsbStor = 'HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR'
$machineAppIdSvc = 'HKLM\SYSTEM\CurrentControlSet\Services\AppIDSvc'

Set-GpoReg $ComputerGpoName $machineInstaller 'AlwaysInstallElevated' 0 DWord 'Disabled Always install with elevated privileges for computers'
Set-GpoReg $ComputerGpoName $machineInstaller 'DisableMSI' 1 DWord 'Blocked unmanaged Windows Installer packages'
Set-GpoReg $ComputerGpoName $machineInstaller 'DisableUserInstalls' 1 DWord 'Prohibited per-user Windows Installer installs'
Set-GpoReg $ComputerGpoName $machineUsbStor 'Start' 4 DWord 'Disabled USB mass storage driver'
Set-GpoReg $ComputerGpoName $machineExplorer 'NoDriveTypeAutoRun' 255 DWord 'Disabled AutoRun on all drive types'
Set-GpoReg $ComputerGpoName $machineExplorer 'NoAutorun' 1 DWord 'Disabled AutoPlay/AutoRun behavior'
Set-GpoReg $ComputerGpoName $machineWinlogon 'CachedLogonsCount' '1' String 'Restricted cached interactive logons to one'
Set-GpoReg $ComputerGpoName $machineWDigest 'UseLogonCredential' 0 DWord 'Disabled WDigest credential storage'
Set-GpoReg $ComputerGpoName $machineLsa 'RunAsPPL' 1 DWord 'Enabled LSA protection'
Set-GpoReg $ComputerGpoName $machineLsa 'RunAsPPLBoot' 1 DWord 'Enabled LSA protection at boot'
Set-GpoReg $ComputerGpoName $machineLsa 'DisableDomainCreds' 1 DWord 'Prevented storage of domain credentials for network authentication'
Set-GpoReg $ComputerGpoName $machineAppIdSvc 'Start' 2 DWord 'Configured Application Identity service for AppLocker support'

Update-SecurityTemplate -GpoName $ComputerGpoName
Configure-AppLockerAuditPolicy -GpoName $ComputerGpoName

Export-GpoReportPair -Phase 'after'
Ensure-GpoLinked -GpoName $UserGpoName -TargetOu $UserTargetOu
Ensure-GpoLinked -GpoName $ComputerGpoName -TargetOu $ComputerTargetOu

$userGpo = Get-GPO -Name $UserGpoName -Domain $Domain -Server $GpoServer
$computerGpo = Get-GPO -Name $ComputerGpoName -Domain $Domain -Server $GpoServer
$applockerXml = Get-AppLockerPolicy -LDAP "LDAP://CN={$($computerGpo.Id)},CN=Policies,CN=System,DC=corp,DC=local" -Xml
if ($applockerXml -match 'EnforcementMode="AuditOnly"') {
    Add-Validation 'Confirmed AppLocker policy contains AuditOnly rule collections.'
} else {
    Add-Validation 'WARNING: AppLocker audit mode was not confirmed from LDAP export.'
}

$report = @()
$report += '# CORP Managed Users and Workstations GPO Hardening Report'
$report += ''
$report += "| Item | Value |"
$report += "|---|---|"
$report += "| Timestamp | $Timestamp |"
$report += "| Executed From | $env:COMPUTERNAME |"
$report += "| User GPO | $UserGpoName ($($userGpo.Id)) |"
$report += "| User Target OU | $UserTargetOu |"
$report += "| Computer GPO | $ComputerGpoName ($($computerGpo.Id)) |"
$report += "| Computer Target OU | $ComputerTargetOu |"
$report += "| Export Folder | $ExportRoot |"
$report += ''
$report += '## Changes Applied'
$report += ''
foreach ($change in $Changes) { $report += "- $change" }
$report += ''
$report += '## Validation'
$report += ''
foreach ($item in $Validation) { $report += "- $item" }
$report += ''
$report += '## Follow-Up Testing'
$report += ''
$report += '- Run `gpupdate /force` on `WS-01` and `LAPTOP-STG-01`.'
$report += '- Use `gpresult /h` or `gpresult /r` to confirm user and computer policy application.'
$report += '- Review AppLocker audit events before switching any rule collection from AuditOnly to Enforced.'
$report += '- Verify multi-display Display and Project pages remain available to managed users.'
$report += ''
$report += '## Exported Evidence'
$report += ''
$report += ('- Before reports: `{0}\before`' -f $ExportRoot)
$report += ('- After reports: `{0}\after`' -f $ExportRoot)
$report += ('- Security template backups: `GptTmpl-before-{0}.inf`, `GptTmpl-after-{0}.inf`' -f $Timestamp)

Set-Content -LiteralPath $ReportPath -Value $report -Encoding UTF8

[pscustomobject]@{
    Timestamp = $Timestamp
    ExportRoot = $ExportRoot
    ReportPath = $ReportPath
    UserGpoModified = $userGpo.ModificationTime
    ComputerGpoModified = $computerGpo.ModificationTime
    ChangeCount = $Changes.Count
    ValidationCount = $Validation.Count
} | ConvertTo-Json -Depth 4
