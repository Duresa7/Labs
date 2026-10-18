# Sources

## Live response and order of volatility

- **RFC 3227, "Guidelines for Evidence Collection and Archiving."** `https://www.rfc-editor.org/rfc/rfc3227`
  The order-of-volatility principle that drives the [live-response runbook](live-response-commands.md): collect the most fragile evidence (memory, network state, processes) before the least (disk).
- **SANS, "Windows live response / triage" guidance and the Microsoft command references** for `whoami`, `ipconfig`, `netstat`, `tasklist`, and `Get-Process`. `https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands`

## Forensic imaging

- **Exterro FTK Imager user guide.** `https://www.exterro.com/digital-forensics-software/ftk-imager`
  The tool used to acquire the AD1 image and to compute and verify the MD5 and SHA-1 hashes at acquisition.
- **NIST, "Digital Evidence" / SP 800-86, "Guide to Integrating Forensic Techniques into Incident Response."** `https://csrc.nist.gov/pubs/sp/800/86/final`
  Background for hashing, chain of custody, and working from an image rather than live evidence.

## Indicators

- **OpenIOC framework (Mandiant).** `https://github.com/mandiant/OpenIOC_1.1`
  The indicator schema and the AND/OR compound-indicator logic used in [indicators.md](indicators.md).
- **MITRE ATT&CK, T1547.001 "Boot or Logon Autostart Execution: Registry Run Keys."** `https://attack.mitre.org/techniques/T1547/001/`
  The persistence technique that the registry-Run-key indicator detects.

## Packet and event-log analysis

- **Wireshark User's Guide.** `https://www.wireshark.org/docs/wsug_html_chunked/`
  Reference for display filters and packet-capture analysis used in the scoping workflow.
- **Microsoft, Event ID 4624 "An account was successfully logged on."** `https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4624`
  Used to interpret the successful interactive logon in the event-log report.
- **Microsoft, Event ID 4672 "Special privileges assigned to new logon."** `https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4672`
  Used to interpret the `SeDebugPrivilege` finding.
- **Microsoft, Event ID 4688 process creation auditing.** `https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4688`
  Used as the missing process-creation signal in the default-log gap.
- **Microsoft Sysinternals, Sysmon.** `https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon`
  Reference for adding process, network, and file-creation telemetry beyond default Security logs.
- **Microsoft Defender ASR rules reference.** `https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference`
  Reference for the LSASS credential-stealing protection recommendation.
