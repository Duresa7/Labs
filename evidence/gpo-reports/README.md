# GPO Reports — Evidence

This folder contains **exports of Group Policy Objects from the lab's live Active
Directory domain**. The files were produced from GPO settings-report backups
(`gpreport.xml` exports captured on 2026-04-25 / 2026-04-26). The policy *content* (security
settings, registry hardening, AppLocker rules, firewall rules, and the browser allow/deny
lists) is preserved unchanged so the evidence stays technically faithful. Each Markdown file is
hand-authored from the corresponding `gpreport.xml`; the matching `*-gpreport.xml` is the same
source export.

## Files

| GPO | Readable settings | Raw export | Description | Backup date |
|-----|-------------------|------------|-------------|-------------|
| **GPO-ManagedWorkstations-Security** | [`gpo-managedworkstations-security-settings.md`](./gpo-managedworkstations-security-settings.md) | [`gpo-managedworkstations-security-gpreport.xml`](./gpo-managedworkstations-security-gpreport.xml) | Machine-side hardening baseline for the Managed Workstations OU: security template (user rights, inactivity lock, restricted groups), LSA/credential hardening, USB-storage block, AppLocker enforcement, Windows Firewall RDP rules, Chrome/Edge machine policies, and the 178-domain URL allowlist with default-deny. | 2026-04-26 |
| **GPO-ManagedUsers-Restrictions** | [`gpo-managedusers-restrictions-settings.md`](./gpo-managedusers-restrictions-settings.md) | [`gpo-managedusers-restrictions-gpreport.xml`](./gpo-managedusers-restrictions-gpreport.xml) | User-side restrictions for managed accounts (filtered to `CORP\GRP-ManagedUsers`): Settings page allowlist, personalization/network lockdown, blocked admin tools and game launchers, MMC snap-in lockdown, and the same Chrome/Edge URL allow/deny content filter at user scope. | 2026-04-26 |

## Scope note

The backup archives provided for this evidence set contained settings reports for **two** GPOs
only — `GPO-ManagedWorkstations-Security` and `GPO-ManagedUsers-Restrictions`. Two other GPOs
that exist in the broader lab — **`GPO-PasswordPolicy`** and **`Managed Workstations - OpenSSH
Server`** — were **not present** in any of the supplied backup archives, so no report
could be generated for them here. They will be added once their `gpreport.xml` backups are
available.
