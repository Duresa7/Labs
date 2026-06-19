# AppLocker targeted deny rules

Sanitized summary of the enforced AppLocker ruleset used by
`GPO-ManagedWorkstations-Security`.

This is not a full XML export. The raw export is evidence-only source material;
this file records the publishable rule structure without domain SIDs, internal
hostnames, or source archive names.

## Rule collections

| Collection | Enforcement | Base allow rules | Targeted deny rules |
|---|---|---|---|
| Executable | Enabled | `%WINDIR%\*`, `%PROGRAMFILES%\*`, `%PROGRAMFILES% (x86)\*`, local administrators | User-writable executable paths plus named game and launcher executables |
| Script | Enabled | `%WINDIR%\*`, `%PROGRAMFILES%\*`, `%PROGRAMFILES% (x86)\*`, local administrators | User-writable script paths |
| MSI | Enabled | `%WINDIR%\*`, `%PROGRAMFILES%\*`, `%PROGRAMFILES% (x86)\*`, local administrators | User-writable installer paths |
| DLL | Enabled | `%WINDIR%\*`, `%PROGRAMFILES%\*`, `%PROGRAMFILES% (x86)\*`, local administrators | User-writable DLL paths |
| Packaged apps | Enabled | Signed packaged apps | No AppLocker packaged-app deny; user and browser policy handle the unwanted app paths |

## User-writable paths denied

The deny rules target locations a standard user can write to:

```text
%OSDRIVE%\Users\*\Downloads\*
%OSDRIVE%\Users\*\Desktop\*
%OSDRIVE%\Users\*\AppData\Local\Temp\*
%OSDRIVE%\Users\*\AppData\Local\Programs\*
%OSDRIVE%\Users\*\OneDrive\Downloads\*
%OSDRIVE%\Users\*\OneDrive\Desktop\*
```

The executable and installer collections also include per-user launcher paths
under profile-local app data and the Start Menu.

## Named executable denies

The executable collection includes named denies for common game and launcher
processes:

```text
RobloxPlayerBeta.exe
RobloxPlayerInstaller.exe
RobloxStudioInstaller.exe
RobloxStudioBeta.exe
Steam.exe
steamwebhelper.exe
EpicGamesLauncher.exe
FortniteClient-Win64-Shipping.exe
MinecraftLauncher.exe
RiotClientServices.exe
Battle.net.exe
XboxPcApp.exe
GameBar.exe
GameBarFTServer.exe
```

Normal documents, images, Markdown, PDFs, and source files are not blocked by
these rules unless they try to launch executable content from a denied path.
