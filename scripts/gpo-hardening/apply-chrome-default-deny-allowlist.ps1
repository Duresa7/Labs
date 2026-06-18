<#
.SYNOPSIS
  Applies a Chrome default-deny URL policy with an education/dev allowlist.
.DESCRIPTION
  Sets a default-deny Chrome URL policy (URLBlocklist = *) in both the managed-user
  and managed-workstation GPOs, then allows an explicit list of Google identity,
  YouTube (restricted), coding/developer, education, productivity, AI, and CDN
  domains via URLAllowlist. Exports before/after evidence and the allowlist.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'Stop'
Import-Module GroupPolicy

$Domain = 'corp.local'
$GpoServer = 'CORP-DC01.corp.local'
$UserGpo = 'GPO-ManagedUsers-Restrictions'
$ComputerGpo = 'GPO-ManagedWorkstations-Security'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceRoot = "C:\Windows\Temp\corp-chrome-default-deny-allowlist-$Timestamp"
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
    param([string]$GpoName, [string]$Hive, [string]$SubKey, [string[]]$Values)
    $key = "$Hive\Software\Policies\Google\Chrome\$SubKey"
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
    # Google identity, search, classroom, docs, and support domains.
    'accounts.google.com',
    'myaccount.google.com',
    'mail.google.com',
    'docs.google.com',
    'drive.google.com',
    'classroom.google.com',
    'calendar.google.com',
    'contacts.google.com',
    'keep.google.com',
    'tasks.google.com',
    'google.com',
    'www.google.com',
    'encrypted.google.com',
    'ogs.google.com',
    'ssl.gstatic.com',
    'gstatic.com',
    '*.gstatic.com',
    'googleusercontent.com',
    '*.googleusercontent.com',
    'googleapis.com',
    '*.googleapis.com',
    'ggpht.com',
    '*.ggpht.com',
    'clients2.google.com',
    'clients2.googleusercontent.com',

    # YouTube learning, with restricted mode still forced by policy.
    'youtube.com',
    '*.youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    '*.youtube-nocookie.com',
    'ytimg.com',
    '*.ytimg.com',
    'googlevideo.com',
    '*.googlevideo.com',

    # Coding and developer learning.
    'freecodecamp.org',
    '*.freecodecamp.org',
    'github.com',
    'gist.github.com',
    'docs.github.com',
    'raw.githubusercontent.com',
    'githubusercontent.com',
    '*.githubusercontent.com',
    'stackoverflow.com',
    '*.stackoverflow.com',
    'stackexchange.com',
    '*.stackexchange.com',
    'developer.mozilla.org',
    'mdn.dev',
    'w3schools.com',
    '*.w3schools.com',
    'python.org',
    '*.python.org',
    'docs.python.org',
    'pypi.org',
    '*.pypi.org',
    'files.pythonhosted.org',
    'npmjs.com',
    '*.npmjs.com',
    'nodejs.org',
    '*.nodejs.org',
    'git-scm.com',
    'code.visualstudio.com',
    'marketplace.visualstudio.com',
    'visualstudio.microsoft.com',
    'learn.microsoft.com',
    'developer.microsoft.com',
    'devdocs.io',
    'replit.com',
    '*.replit.com',
    'codepen.io',
    '*.codepen.io',
    'codesandbox.io',
    '*.codesandbox.io',
    'jsfiddle.net',
    'glitch.com',
    '*.glitch.com',
    'kaggle.com',
    '*.kaggle.com',

    # Education, research, and productivity.
    'khanacademy.org',
    '*.khanacademy.org',
    'coursera.org',
    '*.coursera.org',
    'edx.org',
    '*.edx.org',
    'quizlet.com',
    '*.quizlet.com',
    'wikipedia.org',
    '*.wikipedia.org',
    'wiktionary.org',
    '*.wiktionary.org',
    'britannica.com',
    '*.britannica.com',
    'desmos.com',
    '*.desmos.com',
    'wolframalpha.com',
    '*.wolframalpha.com',
    'office.com',
    '*.office.com',
    'microsoft365.com',
    '*.microsoft365.com',
    'live.com',
    '*.live.com',
    'onedrive.live.com',
    'sharepoint.com',
    '*.sharepoint.com',
    'officeapps.live.com',
    'officecdn.microsoft.com',

    # AI and assisted learning.
    'chatgpt.com',
    '*.chatgpt.com',
    'chat.openai.com',
    'openai.com',
    '*.openai.com',
    'claude.ai',
    '*.claude.ai',
    'gemini.google.com',
    'copilot.microsoft.com',
    'perplexity.ai',
    '*.perplexity.ai',

    # Common CDNs used by coding/education sites.
    'jsdelivr.net',
    '*.jsdelivr.net',
    'unpkg.com',
    '*.unpkg.com',
    'cdnjs.cloudflare.com',
    'cloudflare.com',
    '*.cloudflare.com',
    'cloudflareinsights.com',
    '*.cloudflareinsights.com'
)

$allow = $allow | Sort-Object -Unique

foreach ($target in @(
    [pscustomobject]@{Gpo=$UserGpo;Hive='HKCU'},
    [pscustomobject]@{Gpo=$ComputerGpo;Hive='HKLM'}
)) {
    Set-List -GpoName $target.Gpo -Hive $target.Hive -SubKey 'URLBlocklist' -Values @('*')
    Set-List -GpoName $target.Gpo -Hive $target.Hive -SubKey 'URLAllowlist' -Values $allow
}

Set-Content -LiteralPath (Join-Path $EvidenceRoot 'url-allowlist.txt') -Value $allow -Encoding UTF8
Export-Reports -Phase 'after'
Compress-Archive -Path $EvidenceRoot\* -DestinationPath "$EvidenceRoot.zip" -Force

[pscustomobject]@{
    UserGpo = $UserGpo
    ComputerGpo = $ComputerGpo
    Mode = 'Default deny URLBlocklist=* with URLAllowlist'
    AllowlistCount = $allow.Count
    Evidence = "$EvidenceRoot.zip"
} | ConvertTo-Json -Depth 4
