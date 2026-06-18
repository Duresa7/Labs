# Screenshot evidence

This folder holds the visual proof referenced from the chapters. Each chapter calls out specific screenshot slots; drop the matching image here with the filename shown and it will render in the doc.

Capture screenshots on the real systems, then sanitize anything on screen the same way the rest of the repo is sanitized: blur or relabel real hostnames, usernames, public IPs, and tenant names so they match the placeholders (`corp.local`, `CORP-DC01`, `jack-user`, `corplab.example.com`).

| File | Chapter | Should show |
|---|---|---|
| `01-replsummary.png` | 01 | `repadmin /replsummary` with zero failures across the DC pair |
| `01-ou-tree.png` | 01 | Active Directory Users and Computers with the OU tree expanded |
| `02-chrome-policy.png` | 02 | `chrome://policy` on a managed endpoint: the URL allowlist and the two allowed extensions |
| `02-gpmc-workstation.png` | 02 | Group Policy Management Console settings report for `GPO-ManagedWorkstations-Security` |
| `03-sync-status.png` | 03 | Entra admin center sync status, last sync recent |
| `03-synced-user.png` | 03 | Entra Users list, `jack-user` with "Directory synced: Yes" |
| `03-dsregcmd.png` | 03 | `dsregcmd /status` on `LAPTOP-01`: `AzureAdJoined` and `DomainJoined` both YES |
| `04-backup-jobs.png` | 04 | Recovery Services vault, completed system-state backup jobs |
| `04-asr-testfailover.png` | 04 | ASR test failover completed, recovery VM running in Azure |
| `04-dcdiag.png` | 04 | `dcdiag /v` on the restored DC with passing tests |
| `05-bloodhound.png` | 05 | BloodHound: no path from a managed user to Domain Admins |
| `05-lockout-events.png` | 05 | Event Viewer with `4740` lockout events from the spray |
| `05-responder-after.png` | 05 | Responder returning no hash after the LLMNR fix |
