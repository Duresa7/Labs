# Scripts

The automation behind the lab, grouped by chapter. Read before you run. Every script prompts for any credential instead of storing it, and assumes an elevated session.

## ad-setup ([chapter 01](../docs/01-onprem-ad-build.md))

| Script | Does |
|---|---|
| `install-forest-dc01.ps1` | Installs AD DS and creates the `corp.local` forest on the first DC |
| `promote-corp-dc02.ps1` | Promotes the second DC as a replica and Global Catalog (real build script, credentials prompted) |
| `create-ou-structure.ps1` | Builds the OU tree with accidental-deletion protection |
| `create-users-and-groups.ps1` | Creates the admin and managed accounts and the security groups |
| `collect-dc02-ssh-state.ps1` | Diagnostic: dumps OpenSSH config and service state on a DC |

## gpo-hardening ([chapter 02](../docs/02-gpo-security-hardening.md))

| Script | Does |
|---|---|
| `implement-gpo-hardening.ps1` | The main hardening pass: LSA protection, cached logons, USB, AppLocker staging, security template |
| `apply-targeted-applocker-blocks.ps1` | AppLocker enforced deny rules for user-writable paths and game launchers |
| `apply-chrome-managed-user-policies.ps1` | User-scope Chrome restrictions |
| `apply-chrome-machine-policies.ps1` | Machine-scope Chrome restrictions |
| `apply-chrome-default-deny-allowlist.ps1` | Default-deny URL model with the coding/education allowlist |
| `apply-browser-allowlist-edge-chrome-default.ps1` | Mirrors the allowlist to Edge, sets Chrome as default handler |
| `deploy-wlan-policy.ps1` | Deploys the single allowed Wi-Fi profile (PSK is a runtime parameter) |
| `install-openssh-workstation.ps1` | Installs key-based OpenSSH Server on a workstation |
| `deploy-managed-workstation-ssh-gpo.ps1` | Delivers the OpenSSH install as a machine startup script via GPO |
| `logon-hours-machine-action.ps1` | Machine-side logon-hours enforcer (warns, then logs off) |
| `logon-hours-machine-register.ps1` / `.cmd` | Registers the enforcer as a SYSTEM scheduled task |

## hybrid-identity ([chapter 03](../docs/03-hybrid-identity-entra.md))

| Script | Does |
|---|---|
| `add-upn-suffix.ps1` | Adds the routable UPN suffix and stamps managed users |
| `sync-and-verify.ps1` | Triggers an Entra Connect sync cycle and reports health |
| `verify-synced-users-graph.ps1` | Confirms a user synced and is mastered on-prem (Graph) |

## backup-dr ([chapter 04](../docs/04-backup-and-disaster-recovery.md))

| Script | Does |
|---|---|
| `create-recovery-vault.ps1` | Creates the Azure Recovery Services vault |
| `register-mars-and-backup.ps1` | Registers the MARS agent and schedules DC system-state backup |
| `configure-asr-replication.ps1` | Runbook for ASR replication of the Windows guest (agent path) |

## attack-defend ([chapter 05](../docs/05-attack-and-defend.md))

| Script | Does |
|---|---|
| `attack-chain.sh` | The Kali attack sequence (lab-only, against my own domain) |
| `blue-team-verification.ps1` | Reads the event-log evidence and confirms the controls are live |
