# Sources

## Snort rule writing

- **Snort 3 Rule Writing Guide.** `https://docs.snort.org/`
  Rule header/body structure, the `flags`, `dsize`, `content`, and `classtype` options, and the `$HOME_NET` / `$EXTERNAL_NET` variables used in `rules/local.rules`.
- **Snort default rule classifications (`classification.config`).** `https://www.snort.org/documents`
  Source of the `classtype` values (`bad-unknown`, `attempted-dos`) and the convention that locally authored rules use SIDs at or above 1000000.

## Scan techniques the rules detect

- **Nmap reference guide, "Port Scanning Techniques."** `https://nmap.org/book/man-port-scanning-techniques.html`
  The behavior of the FIN/NULL/Xmas and UDP scans these rules catch. I generated each from the offensive side in [the network recon project](../../offensive/01-network-recon-and-port-scanning/README.md).

## The Windows logging-gap analysis

- **Microsoft, "Audit Process Creation" (Event ID 4688) and command-line auditing.** `https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/command-line-process-auditing`
  Why process-creation events are not logged by default and how to enable them, the core finding of the Mimikatz log review.
- **Microsoft, "Audit Logon" and "Audit Sensitive Privilege Use" (Event IDs 4624, 4672, 4656, 4663).** `https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/advanced-security-audit-policy-settings`
  The events that were present (4624, 4672) versus the object-access events (4656/4663) that were absent.
- **DetectionLab (Chris Long).** `https://github.com/clong/DetectionLab`
  The Windows test environment used to run the credential-dumping tool and capture the Security log.
- **Sysmon, Sysinternals.** `https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon`
  The telemetry source recommended to close the process-creation and LSASS-access gap.
- **MITRE ATT&CK, T1003.001 "OS Credential Dumping: LSASS Memory."** `https://attack.mitre.org/techniques/T1003/001/`
  The technique the Mimikatz run exercised, and the detections ATT&CK suggests for it.
