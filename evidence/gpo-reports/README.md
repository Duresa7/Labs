# GPO Reports — Sanitized Evidence

This folder contains **sanitized exports of Group Policy Objects from the lab's live Active
Directory domain**. The files were produced from real GPO settings-report backups
(`gpreport.xml` exports captured on 2026-04-25 / 2026-04-26). Every real-world identifier —
the production domain name and NetBIOS name, domain and machine SIDs, administrator and user
account names, computer hostnames, the Wi-Fi SSID/passphrase, and private IP ranges — has been
consistently replaced with neutral lab placeholders (`corp.local` / `CORP`,
`S-1-5-21-1111111111-2222222222-3333333333`, `Alex Carter` / `acarter`, `Jack User` /
`jack-user`, `CORP-DC01`, etc.). The actual policy *content* (security settings, registry
hardening, AppLocker rules, firewall rules, and the browser allow/deny lists) is preserved
unchanged so the evidence stays technically faithful. Each Markdown file is hand-authored from
the corresponding `gpreport.xml`; the matching `*-gpreport.xml` is the same source export with
the sanitization map applied.

## Files

| GPO | Readable settings | Raw export | Description | Backup date |
|-----|-------------------|------------|-------------|-------------|
| **GPO-ManagedWorkstations-Security** | [`gpo-managedworkstations-security-settings.md`](./gpo-managedworkstations-security-settings.md) | [`gpo-managedworkstations-security-gpreport.xml`](./gpo-managedworkstations-security-gpreport.xml) | Machine-side hardening baseline for the Managed Workstations OU: security template (user rights, inactivity lock, restricted groups), LSA/credential hardening, USB-storage block, AppLocker enforcement, Windows Firewall RDP rules, Chrome/Edge machine policies, and the 178-domain URL allowlist with default-deny. | 2026-04-26 |
| **GPO-ManagedUsers-Restrictions** | [`gpo-managedusers-restrictions-settings.md`](./gpo-managedusers-restrictions-settings.md) | [`gpo-managedusers-restrictions-gpreport.xml`](./gpo-managedusers-restrictions-gpreport.xml) | User-side restrictions for managed accounts (filtered to `CORP\GRP-ManagedUsers`): Settings page allowlist, personalization/network lockdown, blocked admin tools and game launchers, MMC snap-in lockdown, and the same Chrome/Edge URL allow/deny content filter at user scope. | 2026-04-26 |

## Sanitization summary

| What was replaced | Sanitized (placeholder) |
|-------------------|--------------------------|
| Real domain DNS / NetBIOS name | `corp.local` / `CORP` |
| Real domain SID (`S-1-5-21-<a>-<b>-<c>`) | `S-1-5-21-1111111111-2222222222-3333333333` (RIDs preserved, e.g. `-512` Domain Admins) |
| Real admin account | `CORP\acarter` |
| Real personal display names | `Alex Carter` / `Jack User` |
| Real computer hostnames | `CORP-DC01`, `CORP-DC02`, `LAPTOP-01`, `WS-01`, … |
| Wi-Fi SSID / passphrase | `CorpLab-WiFi` / `[REDACTED-WIFI-PSK]` |
| Real private IP ranges | `10.10.x.x` |
| School / district domains | `school-portal.example.edu` |

GPO GUIDs are not sensitive and are preserved as-is.

## Scope note

The backup archives provided for this evidence set contained settings reports for **two** GPOs
only — `GPO-ManagedWorkstations-Security` and `GPO-ManagedUsers-Restrictions`. Two other GPOs
that exist in the broader lab — **`GPO-PasswordPolicy`** and **`Managed Workstations - OpenSSH
Server`** — were **not present** in any of the supplied backup archives, so no sanitized report
could be generated for them here. They will be added once their `gpreport.xml` backups are
available.
