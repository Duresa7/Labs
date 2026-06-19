# GPO-ManagedWorkstations-Security — Settings Evidence

> Export of the live `GPO-ManagedWorkstations-Security` Group Policy Object.

| Property | Value |
|----------|-------|
| GPO Name | `GPO-ManagedWorkstations-Security` |
| GPO GUID | `{0DC3217F-4AAC-4A5A-843C-CC596C7328DC}` |
| Domain | `corp.local` |
| Linked to (SOM) | `corp.local/Workstations/Managed` |
| Created | 2026-04-04 |
| Last modified | 2026-04-26 |
| Computer config | Enabled |
| User config | Enabled (no user-side settings configured) |
| Owner | `CORP\Domain Admins` (`S-1-5-21-...-512`) |

This GPO is the machine-side hardening baseline applied to the **Managed Workstations** OU.
It combines a security template, registry-based hardening, AppLocker application control,
Windows Firewall rules, browser machine policies, and a content-filtering allow/deny list.

---

## 1. Security Settings (Security Template)

### User Rights Assignment

| Right | Assigned to |
|-------|-------------|
| `SeRemoteInteractiveLogonRight` (Allow log on through Remote Desktop Services) | `CORP\Domain Admins` |
| `SeSystemTimePrivilege` (Change the system time) | `BUILTIN\Administrators`, `NT AUTHORITY\LOCAL SERVICE` |

### Security Options

| Policy | Value |
|--------|-------|
| Interactive logon: Machine inactivity limit | `1200` seconds (20 min) |
| Accounts: Administrator account status (`EnableAdminAccount`) | Disabled (`0`) |

### Restricted Groups

| Group | Enforced members |
|-------|------------------|
| `CORP\Domain Admins` | `CORP\acarter` |
| `BUILTIN\Administrators` | `CORP\Domain Admins` |

---

## 2. Administrative Templates (Computer)

| Setting | State | Detail |
|---------|-------|--------|
| Windows Defender Firewall: Protect all network connections (Domain Profile) | Enabled | — |
| Always wait for the network at computer startup and logon | Enabled | — |
| Set the default behavior for AutoRun | Enabled | Do not execute any autorun commands |
| Turn off Autoplay | Enabled | All drives |
| Set a default associations configuration file | Enabled | `\\corp.local\SYSVOL\corp.local\Policies\{0DC3217F-4AAC-4A5A-843C-CC596C7328DC}\Machine\CORP\ChromeDefaultAssociations.xml` |
| Allow users to connect remotely by using Remote Desktop Services | Enabled | — |
| Turn off the Store application | Enabled | — |
| Always install with elevated privileges | Disabled | — |
| Prohibit User Installs | Enabled | Hide User Installs |
| Turn off Windows Installer | Enabled | For non-managed applications only |

---

## 3. Registry-Based Hardening (Preferences & Policies)

### Credential / LSA hardening

| Hive\Key | Value | Data | Effect |
|----------|-------|------|--------|
| `HKLM\SYSTEM\CurrentControlSet\Control\Lsa` | `RunAsPPL` | `1` | LSASS runs as Protected Process Light |
| `HKLM\SYSTEM\CurrentControlSet\Control\Lsa` | `RunAsPPLBoot` | `1` | LSASS PPL enforced at boot |
| `HKLM\SYSTEM\CurrentControlSet\Control\Lsa` | `DisableDomainCreds` | `1` | Disallow storage of network credentials |
| `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest` | `UseLogonCredential` | `0` | No plaintext creds in memory (WDigest) |
| `HKLM\...\Winlogon` | `CachedLogonsCount` | `0` | No cached domain logons |
| `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` | `ForceUnlockLogon` | `1` | Re-authenticate to DC on unlock |

### Device / service hardening

| Hive\Key | Value | Data | Effect |
|----------|-------|------|--------|
| `HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR` | `Start` | `4` | USB mass-storage driver disabled |
| `HKLM\SYSTEM\CurrentControlSet\Services\AppIDSvc` | `Start` | `2` | Application Identity service auto-start (required for AppLocker) |

### Remote Desktop

| Hive\Key | Value | Data | Effect |
|----------|-------|------|--------|
| `HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server` | `fDenyTSConnections` | `0` | RDP connections allowed |

### Time zone

| Hive\Key | Value | Data |
|----------|-------|------|
| `HKLM\...\Time Zone` | `TimeZoneKeyName` | `Eastern Standard Time` |
| `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` | `TimeZoneKeyName` | `Eastern Standard Time` |

### Browser machine policies (Google Chrome)

| Value | Data | Effect |
|-------|------|--------|
| `BrowserSignin` | `1` | Sign-in enabled |
| `SyncDisabled` | `1` | Browser sync disabled |
| `IncognitoModeAvailability` | `1` | Incognito mode disabled |
| `BrowserGuestModeEnabled` | `0` | Guest mode disabled |
| `BrowserAddPersonEnabled` | `0` | Adding profiles disabled |
| `ForceGoogleSafeSearch` | `1` | SafeSearch forced |
| `ForceYouTubeRestrict` | `2` | YouTube Strict Restricted Mode |

### Chrome extension control

| Key | Entries |
|-----|---------|
| `ExtensionInstallBlocklist` | `*` (block all by default) |
| `ExtensionInstallAllowlist` | `ddkjiahejlhfcafbddmgiahcphecmpfh`, `ghbmnnjooekpmoecnnnilnnbdlolhkhi` |
| `ExtensionInstallForcelist` | `ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx`, `ghbmnnjooekpmoecnnnilnnbdlolhkhi;https://clients2.google.com/service/update2/crx` |

---

## 4. Windows Firewall

Firewall is enabled on **all three profiles** (Domain, Private, Public). Policy version `545`.

### Inbound rules

| Rule | Action | Program / Service | Local Port | Protocol |
|------|--------|-------------------|------------|----------|
| Remote Desktop - Shadow (UDP) `@FirewallAPI.dll,-28776` | Allow | `svchost.exe` / `termservice` | 3389 | UDP (17) |
| Remote Desktop - User Mode (TCP-In) | Allow | `System` | 3389 | TCP (6) |
| Remote Desktop - Shadow (TCP) `@FirewallAPI.dll,-28778` | Allow | `%SystemRoot%\system32\RdpSa.exe` | — | TCP (6) |

---

## 5. Application Control Policies (AppLocker)

All five rule collections are set to **Enforce** (`EnforcementMode = Enabled`):
Appx (packaged apps), Exe, Msi, Dll, and Script.

### Common patterns across Exe / Msi / Dll / Script collections

- **Allow base rules** (`Everyone`, SID `S-1-1-0`) for the trusted system locations:
  `%PROGRAMFILES%\*`, `%PROGRAMFILES% (x86)\*`, `%WINDIR%\*`.
- **Allow Administrators all** (`BUILTIN\Administrators`, SID `S-1-5-32-544`, path `*`) — admins bypass the targeted blocks.
- **Deny user-writable locations** (`Everyone`) so code cannot run from per-user / download folders:
  `%OSDRIVE%\Users\*\Downloads\*`, `...\Desktop\*`, `...\OneDrive\Downloads\*`, `...\OneDrive\Desktop\*`,
  `...\AppData\Local\Temp\*`, `...\AppData\Local\Programs\*`,
  `...\AppData\Local\Steam\*`, `...\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Steam\*`,
  `...\AppData\Local\Roblox\*`, `...\AppData\Roaming\Roblox\*`.

### Appx (packaged apps)

| Rule | Action | Condition |
|------|--------|-----------|
| Allow signed packaged apps | Allow (`Everyone`) | Any publisher (`*`) — Store/Xbox access blocked separately via user policy |

### Exe — explicit game / launcher denies (`Everyone`)

Blocked executable names (`*\<name>`):

`FortniteClient-Win64-Shipping.exe`, `XboxPcApp.exe`, `GameBar.exe`, `GameBarFTServer.exe`,
`Steam.exe`, `steamwebhelper.exe`, `EpicGamesLauncher.exe`, `MinecraftLauncher.exe`,
`RiotClientServices.exe`, `Battle.net.exe`, `RobloxPlayerBeta.exe`, `RobloxPlayerInstaller.exe`,
`RobloxStudioBeta.exe`, `RobloxStudioInstaller.exe`.

---

## 6. Content Filtering — Browser URL Lists (machine scope)

The same allow/deny model is applied to **both Google Chrome and Microsoft Edge** machine policies.

### Default deny

| Browser | `URLBlocklist` baseline |
|---------|--------------------------|
| Microsoft Edge | `*` (block everything, allow only the allowlist) |
| Google Chrome | `*` plus explicit gaming/social entries (see below) |

### Chrome URL blocklist (explicit entries beyond `*`)

Roblox, Steam (`steampowered.com`, `steamcommunity.com`, `store.steampowered.com`),
Epic Games, Fortnite, Minecraft, Xbox play, Discord (`discord.com`, `discordapp.com`),
Twitch, Battle.net, Riot Games, League of Legends — listed both as bare domains/wildcards
and as `*://...` scheme-qualified patterns.

### URL allowlist (178 entries, identical for Chrome and Edge)

The allowlist permits only education, coding, documentation, AI, and Microsoft/Google
productivity domains. Full list:

```
*.angular.dev            *.boot.dev               *.britannica.com         *.chatgpt.com
*.claude.ai              *.cloudflare.com         *.cloudflareinsights.com *.codecademy.com
*.codepen.io             *.codesandbox.io         *.codewars.com           *.coursera.org
*.desmos.com             *.edx.org                *.freecodecamp.org       *.ggpht.com
*.githubusercontent.com  *.glitch.com             *.go.dev                 *.googleapis.com
*.googleusercontent.com  *.googlevideo.com        *.gstatic.com            *.java.com
*.jsdelivr.net           *.kaggle.com             *.khanacademy.org        *.kotlinlang.org
*.leetcode.com           *.live.com               *.microsoft365.com       *.nextjs.org
*.nodejs.org             *.npmjs.com              *.nuget.org              *.office.com
*.openai.com             *.perplexity.ai          *.php.net                *.pypi.org
*.python.org             *.quizlet.com            *.react.dev              *.replit.com
*.ruby-lang.org          *.rubyonrails.org        *.rust-lang.org          *.scrimba.com
*.sharepoint.com         *.stackexchange.com      *.stackoverflow.com      *.svelte.dev
*.swift.org              *.tailwindcss.com        *.typescriptlang.org     *.udemy.com
*.unpkg.com              *.vite.dev               *.vuejs.org              *.w3schools.com
*.wikipedia.org          *.wiktionary.org         *.wolframalpha.com       *.youtube.com
*.youtube-nocookie.com   *.ytimg.com              accounts.google.com      angular.dev
boot.dev                 britannica.com           calendar.google.com      cdnjs.cloudflare.com
chat.openai.com          chatgpt.com              classroom.google.com     claude.ai
clients2.google.com      clients2.googleusercontent.com                    cloudflare.com
cloudflareinsights.com   code.visualstudio.com    codecademy.com           codepen.io
codesandbox.io           codewars.com             contacts.google.com      copilot.microsoft.com
coursera.org             desmos.com               devdocs.io               developer.android.com
developer.microsoft.com  developer.mozilla.org    doc.rust-lang.org        docs.github.com
docs.google.com          docs.npmjs.com           docs.oracle.com          docs.python.org
dotnet.microsoft.com     drive.google.com         edx.org                  encrypted.google.com
files.pythonhosted.org   freecodecamp.org         gemini.google.com        ggpht.com
gist.github.com          github.com               githubusercontent.com    git-scm.com
glitch.com               go.dev                   google.com               googleapis.com
googleusercontent.com    googlevideo.com          gstatic.com              java.com
jsdelivr.net             jsfiddle.net             kaggle.com               keep.google.com
khanacademy.org          kotlinlang.org           learn.microsoft.com      leetcode.com
live.com                 mail.google.com          marketplace.visualstudio.com               mdn.dev
microsoft365.com         myaccount.google.com     nextjs.org               nodejs.org
npmjs.com                nuget.org                office.com               officeapps.live.com
officecdn.microsoft.com  ogs.google.com           onedrive.live.com        openai.com
perplexity.ai            php.net                  pypi.org                 python.org
quizlet.com              raw.githubusercontent.com                         react.dev
replit.com               ruby-lang.org            rubyonrails.org          rust-lang.org
scrimba.com              sharepoint.com           ssl.gstatic.com          stackexchange.com
stackoverflow.com        svelte.dev               swift.org                tailwindcss.com
tasks.google.com         typescriptlang.org       udemy.com                unpkg.com
visualstudio.microsoft.com                        vite.dev                 vuejs.org
w3schools.com            wikipedia.org            wiktionary.org           wolframalpha.com
www.google.com           youtu.be                 youtube.com              youtube-nocookie.com
ytimg.com
```

---

*Source: `gpo-managedworkstations-security-gpreport.xml` (raw export, same folder).*
