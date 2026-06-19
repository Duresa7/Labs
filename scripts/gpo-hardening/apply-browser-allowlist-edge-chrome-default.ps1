<#
.SYNOPSIS
  Applies a default-deny URL allowlist for Chrome and Edge, with Chrome as default.
.DESCRIPTION
  Sets a default-deny URL policy (URLBlocklist = *) plus an education/dev/AI
  URLAllowlist for both Google Chrome and Microsoft Edge in the managed-user and
  managed-workstation GPOs, blocks Edge launch for managed users, and configures
  Chrome as the default browser via default application associations. Exports
  before/after evidence.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'
Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$UserGpo = 'GPO-ManagedUsers-Restrictions'
$ComputerGpo = 'GPO-ManagedWorkstations-Security'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-browser-allowlist-edge-chrome-default-$Timestamp"
New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null

function Set-GpoValue {
    param([string]$GpoName, [string]$Key, [string]$Name, [ValidateSet('DWord','String')] [string]$Type, $Value)
    try {
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    } catch {
        Start-Sleep -Seconds 2
        Set-GPRegistryValue -Name $GpoName -Domain $Domain -Server $GpoServer -Key $Key -ValueName $Name -Type $Type -Value $Value -ErrorAction Stop | Out-Null
    }
}

function Set-List {
    param([string]$GpoName, [string]$Hive, [string]$VendorPath, [string]$SubKey, [string[]]$Values)
    $key = "$Hive\Software\Policies\$VendorPath\$SubKey"
    for ($i = 0; $i -lt $Values.Count; $i++) {
        Set-GpoValue -GpoName $GpoName -Key $key -Name ([string]($i + 1)) -Type String -Value $Values[$i]
    }
}

function Export-Reports {
    param([string]$Phase)
    $dir = Join-Path $EvidenceRoot $Phase
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    foreach ($g in @($UserGpo, $ComputerGpo)) {
        $safe = $g -replace '[^\w.-]', '_'
        Get-GPOReport -Name $g -Domain $Domain -Server $GpoServer -ReportType Html -Path (Join-Path $dir "$safe.html")
        Get-GPOReport -Name $g -Domain $Domain -Server $GpoServer -ReportType Xml -Path (Join-Path $dir "$safe.xml")
    }
}

Export-Reports -Phase 'before'

$allow = @(
    'accounts.google.com','myaccount.google.com','mail.google.com','docs.google.com','drive.google.com','classroom.google.com','calendar.google.com','contacts.google.com','keep.google.com','tasks.google.com',
    'google.com','www.google.com','encrypted.google.com','ogs.google.com','ssl.gstatic.com','gstatic.com','*.gstatic.com','googleusercontent.com','*.googleusercontent.com','googleapis.com','*.googleapis.com','ggpht.com','*.ggpht.com','clients2.google.com','clients2.googleusercontent.com',
    'youtube.com','*.youtube.com','youtu.be','youtube-nocookie.com','*.youtube-nocookie.com','ytimg.com','*.ytimg.com','googlevideo.com','*.googlevideo.com',
    'freecodecamp.org','*.freecodecamp.org','codecademy.com','*.codecademy.com','scrimba.com','*.scrimba.com','coursera.org','*.coursera.org','udemy.com','*.udemy.com','leetcode.com','*.leetcode.com','codewars.com','*.codewars.com','boot.dev','*.boot.dev','khanacademy.org','*.khanacademy.org',
    'github.com','gist.github.com','docs.github.com','raw.githubusercontent.com','githubusercontent.com','*.githubusercontent.com','stackoverflow.com','*.stackoverflow.com','stackexchange.com','*.stackexchange.com','developer.mozilla.org','mdn.dev','w3schools.com','*.w3schools.com','python.org','*.python.org','docs.python.org','pypi.org','*.pypi.org','files.pythonhosted.org','npmjs.com','*.npmjs.com','nodejs.org','*.nodejs.org','git-scm.com','code.visualstudio.com','marketplace.visualstudio.com','visualstudio.microsoft.com','learn.microsoft.com','developer.microsoft.com','devdocs.io',
    'react.dev','*.react.dev','angular.dev','*.angular.dev','vuejs.org','*.vuejs.org','svelte.dev','*.svelte.dev','nextjs.org','*.nextjs.org','vite.dev','*.vite.dev','tailwindcss.com','*.tailwindcss.com','typescriptlang.org','*.typescriptlang.org','go.dev','*.go.dev','rust-lang.org','*.rust-lang.org','doc.rust-lang.org','java.com','*.java.com','docs.oracle.com','php.net','*.php.net','ruby-lang.org','*.ruby-lang.org','rubyonrails.org','*.rubyonrails.org','dotnet.microsoft.com','nuget.org','*.nuget.org','docs.npmjs.com','developer.android.com','swift.org','*.swift.org','kotlinlang.org','*.kotlinlang.org',
    'replit.com','*.replit.com','codepen.io','*.codepen.io','codesandbox.io','*.codesandbox.io','jsfiddle.net','glitch.com','*.glitch.com','kaggle.com','*.kaggle.com',
    'edx.org','*.edx.org','quizlet.com','*.quizlet.com','wikipedia.org','*.wikipedia.org','wiktionary.org','*.wiktionary.org','britannica.com','*.britannica.com','desmos.com','*.desmos.com','wolframalpha.com','*.wolframalpha.com','office.com','*.office.com','microsoft365.com','*.microsoft365.com','live.com','*.live.com','onedrive.live.com','sharepoint.com','*.sharepoint.com','officeapps.live.com','officecdn.microsoft.com',
    'chatgpt.com','*.chatgpt.com','chat.openai.com','openai.com','*.openai.com','claude.ai','*.claude.ai','gemini.google.com','copilot.microsoft.com','perplexity.ai','*.perplexity.ai',
    'jsdelivr.net','*.jsdelivr.net','unpkg.com','*.unpkg.com','cdnjs.cloudflare.com','cloudflare.com','*.cloudflare.com','cloudflareinsights.com','*.cloudflareinsights.com'
) | Sort-Object -Unique

foreach ($target in @(
    [pscustomobject]@{Gpo=$UserGpo;Hive='HKCU'},
    [pscustomobject]@{Gpo=$ComputerGpo;Hive='HKLM'}
)) {
    foreach ($vendor in @('Google\Chrome','Microsoft\Edge')) {
        Set-List -GpoName $target.Gpo -Hive $target.Hive -VendorPath $vendor -SubKey 'URLBlocklist' -Values @('*')
        Set-List -GpoName $target.Gpo -Hive $target.Hive -VendorPath $vendor -SubKey 'URLAllowlist' -Values $allow
    }
}

# Keep Chrome controls present; Edge gets URL policy too, but managed users are blocked from launching Edge.
$chromeBaseUser = 'HKCU\Software\Policies\Google\Chrome'
Set-GpoValue $UserGpo $chromeBaseUser 'SyncDisabled' DWord 1
Set-GpoValue $UserGpo $chromeBaseUser 'IncognitoModeAvailability' DWord 1
Set-GpoValue $UserGpo $chromeBaseUser 'BrowserGuestModeEnabled' DWord 0

Set-GpoValue $UserGpo 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'DisallowRun' DWord 1
Set-GpoValue $UserGpo 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun' '40' String 'msedge.exe'
Set-GpoValue $UserGpo 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun' '41' String 'MicrosoftEdge.exe'

# Chrome default app association policy for managed workstations.
$computerGpoObject = Get-GPO -Name $ComputerGpo -Domain $Domain -Server $GpoServer
$guid = $computerGpoObject.Id.ToString('B').ToUpperInvariant()
$policyRoot = "\\$Domain\SYSVOL\$Domain\Policies\$guid"
$assocDir = Join-Path $policyRoot 'Machine\CORP'
New-Item -ItemType Directory -Path $assocDir -Force | Out-Null
$assocPath = Join-Path $assocDir 'ChromeDefaultAssociations.xml'
$assocXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
'@
Set-Content -LiteralPath $assocPath -Value $assocXml -Encoding UTF8
Set-GpoValue $ComputerGpo 'HKLM\Software\Policies\Microsoft\Windows\System' 'DefaultAssociationsConfiguration' String $assocPath

Set-Content -LiteralPath (Join-Path $EvidenceRoot 'url-allowlist.txt') -Value $allow -Encoding UTF8
Set-Content -LiteralPath (Join-Path $EvidenceRoot 'ChromeDefaultAssociations.xml') -Value $assocXml -Encoding UTF8
Export-Reports -Phase 'after'
Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    UserGpo = $UserGpo
    ComputerGpo = $ComputerGpo
    AllowlistCount = $allow.Count
    EdgeBlockedForManagedUsers = $true
    ChromeDefaultAssociations = $assocPath
    Evidence = "$EvidenceRoot.zip"
} | ConvertTo-Json -Depth 4
