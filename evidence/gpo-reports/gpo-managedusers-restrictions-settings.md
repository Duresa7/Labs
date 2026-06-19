# GPO-ManagedUsers-Restrictions — Settings Evidence

> Export of the live `GPO-ManagedUsers-Restrictions` Group Policy Object.

| Property | Value |
|----------|-------|
| GPO Name | `GPO-ManagedUsers-Restrictions` |
| Domain | `corp.local` |
| Linked to (SOM) | `corp.local/Users-Accounts/Managed` |
| Security filtering | `CORP\GRP-ManagedUsers` (`DOMAIN-SID-REDACTED`) |
| Created | 2026-04-04 |
| Last modified | 2026-04-26 |
| Computer config | (no settings) |
| User config | Enabled |
| Owner | `CORP\Domain Admins` (`DOMAIN-SID-REDACTED`) |

This GPO is the **user-side** restriction set applied to managed (standard) user accounts in the
**Users-Accounts/Managed** OU and filtered to the `CORP\GRP-ManagedUsers` group. It locks down the
desktop/personalization surface, blocks administrative tools, and applies the same browser
allow/deny content filter as the workstation GPO at user scope.

---

## 1. Administrative Templates (User)

### Control Panel / Personalization

| Setting | State |
|---------|-------|
| Settings Page Visibility | Enabled — `showonly:` allowlist (see below) |
| Prevent changing color and appearance | Enabled |
| Prevent changing desktop background | Enabled |
| Prevent changing desktop icons | Enabled |
| Prevent changing screen saver | Enabled |

**Settings Page Visibility — `showonly:` list** (only these Windows Settings pages are visible):

```
display; project; bluetooth; printers; mousetouchpad; devices-touchpad; typing; pen; autoplay;
usb; appsfeatures; defaultapps; optionalfeatures; maps; tabletmode; taskbar; themes; colors;
lockscreen; background; fonts; dateandtime; regionlanguage; language;
easeofaccess-display; easeofaccess-cursorandpointersize; easeofaccess-magnifier;
easeofaccess-colorfilter; easeofaccess-narrator; easeofaccess-audio; easeofaccess-keyboard;
easeofaccess-mouse; clipboard; notifications; focusassist; storagesense; sound;
windowsupdate; windowsupdate-action; windowsupdate-history; windowsupdate-options;
privacy; privacy-location; privacy-webcam; privacy-microphone; privacy-notifications;
privacy-speech; privacy-feedback; privacy-activityhistory; privacy-backgroundapps
```

### Network Connections

| Setting | State |
|---------|-------|
| Enable Windows 2000 Network Connections settings for Administrators | Enabled |
| Prohibit access to properties of a LAN connection | Enabled |
| Prohibit access to the Advanced Settings item on the Advanced menu | Enabled |

### System / lockdown

| Setting | State | Detail |
|---------|-------|--------|
| Don't run specified Windows applications | Enabled | Disallowed-application list (see below) |
| Prevent access to registry editing tools | Enabled | Disable `regedit` silent run: Yes |
| Remove Change Password (Ctrl+Alt+Del) | Enabled | — |
| Remove Task Manager (Ctrl+Alt+Del) | Enabled | — |
| Restrict users to the explicitly permitted list of snap-ins | Enabled | Permitted list is **empty** — all MMC snap-ins blocked |
| Turn off the Store application | Enabled | — |
| Always install with elevated privileges | Disabled | — |

**Don't run specified Windows applications — disallowed list:**

| Category | Executables |
|----------|-------------|
| Admin / management tools | `mmc.exe`, `msconfig.exe`, `control.exe`, `gpedit.msc`, `secpol.msc`, `lusrmgr.msc` |
| Games / launchers | `RobloxPlayerBeta.exe`, `RobloxPlayerInstaller.exe`, `RobloxStudioInstaller.exe`, `RobloxStudioBeta.exe`, `Steam.exe`, `steamwebhelper.exe`, `EpicGamesLauncher.exe`, `FortniteClient-Win64-Shipping.exe`, `MinecraftLauncher.exe`, `RiotClientServices.exe`, `Battle.net.exe`, `XboxPcApp.exe`, `GameBar.exe`, `GameBarFTServer.exe` |
| Alternate browser (force Chrome) | `msedge.exe`, `MicrosoftEdge.exe` |

---

## 2. Registry-Based Policies (User)

### Network connections (registry-enforced)

| Hive\Key | Value | Data | Effect |
|----------|-------|------|--------|
| `HKCU\Software\Policies\Microsoft\Windows\Network Connections` | `NC_AllowNetBridge_NLA` | `0` | User cannot create a network bridge |
| `HKCU\Software\Policies\Microsoft\Windows\Network Connections` | `NC_ShowSharedAccessUI` | `0` | Internet Connection Sharing UI hidden |

### Command prompt

| Hive\Key | Value | Data | Effect |
|----------|-------|------|--------|
| `HKCU\Software\Policies\Microsoft\Windows\System` | `DisableCMD` | `0` | Command prompt **not** disabled (left enabled for coding shells) |

### Browser policies (Google Chrome — user scope)

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

## 3. Content Filtering — Browser URL Lists (user scope)

Same allow/deny model as the workstation GPO, applied to **Google Chrome and Microsoft Edge**
at user scope.

### Default deny

| Browser | `URLBlocklist` baseline |
|---------|--------------------------|
| Microsoft Edge | `*` (block everything, allow only the allowlist) |
| Google Chrome | `*` plus 26 explicit scheme-qualified gaming/social entries |

### Chrome URL blocklist (`*://...` scheme-qualified entries beyond `*`)

```
*://*.roblox.com/*            *://steampowered.com/*        *://*.steampowered.com/*
*://steamcommunity.com/*      *://*.steamcommunity.com/*    *://store.steampowered.com/*
*://epicgames.com/*           *://*.epicgames.com/*         *://fortnite.com/*
*://*.fortnite.com/*          *://minecraft.net/*           *://*.minecraft.net/*
*://xbox.com/play*            *://www.xbox.com/*/play*      *://discord.com/*
*://*.discord.com/*           *://discordapp.com/*          *://*.discordapp.com/*
*://twitch.tv/*               *://*.twitch.tv/*             *://battle.net/*
*://*.battle.net/*            *://riotgames.com/*           *://*.riotgames.com/*
*://leagueoflegends.com/*     *://*.leagueoflegends.com/*
```

### URL allowlist (178 entries — identical to the workstation GPO)

The allowlist permits only education, coding, documentation, AI, and Microsoft/Google
productivity domains. See
[`gpo-managedworkstations-security-settings.md`](./gpo-managedworkstations-security-settings.md#6-content-filtering--browser-url-lists-machine-scope)
for the full enumerated list (it is byte-for-byte identical between the two GPOs), or the raw
export `gpo-managedusers-restrictions-gpreport.xml`.

---

*Source: `gpo-managedusers-restrictions-gpreport.xml` (raw export, same folder).*
