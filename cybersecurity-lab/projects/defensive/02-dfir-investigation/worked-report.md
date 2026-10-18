# Worked report

## Scope

I combined three host-response lab scenarios into one report: a live triage and forensic-imaging pass on a Windows 11 lab VM, a scoping investigation with packet capture and registry persistence, and a Windows event-log review of a credential-dumping simulation. I did not include raw packet captures, event logs, disk images, IOC files, or provided evidence sets.

## Triage order

I started with volatile data. The order was `whoami`, `ipconfig /all`, `netstat -ano`, `tasklist`, then a full process export. The classic command for the last step, `wmic process list full`, failed because `wmic` is deprecated on modern Windows, so I used:

```powershell
Get-Process | Format-List * > "$env:USERPROFILE\Documents\IR\LiveData\processes.txt"
```

The live data established the host as `DESKTOP-HM66LJC`, user `w11-test`, on `10.0.2.15/24`. `tasklist` captured the simulated suspicious `cmd.exe` process with PID `10564`, tied to `weirdsvc.bat`. `netstat -ano` showed ordinary listening services and several outbound web sessions; the useful response step was mapping the sessions back to PIDs instead of treating every port 443 connection as command and control.

## Image and hash verification

I used FTK Imager to acquire the target folder into an AD1 image. The raw image is not included in the repo. The report keeps the method and result: the image was acquired from the lab user's documents folder, FTK generated MD5 and SHA-1 hashes, and verification returned a match. That gave me a stable copy for offline review without continuing to touch the live host.

## Packet capture findings

The scoping capture had three kinds of traffic: a test alert domain, normal browsing, and ICMP. The suspicious path was the DNS lookup for `testmyids.com`, which resolved to `217.160.0.187` in the exercise. Normal `example.com` and ping traffic gave me baseline context, so the suspicious lookup did not sit alone without comparison.

The second capture was useful because it showed a limit. A plain HTTP filter did not recover web content from modern sites because the sessions were encrypted with TLS or QUIC. I could still use timing, destination, DNS, and protocol metadata, but not the application content.

## Registry persistence

The host had a simulated Run-key entry:

```text
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
  FakeUpdater = C:\Temp\update.exe
```

I exported the user's registry hive and opened it offline. The entry is persistence because Windows runs values under that key at user logon. I hashed the referenced file with SHA-256; it matched the known hash for an empty placeholder file, which confirmed this was a lab artifact rather than a live payload.

## Event-log findings

The credential-dumping lab showed why default Windows Security logs are not enough by themselves. The log showed Event ID `4624` for an interactive logon and Event ID `4672` for special privileges, including `SeDebugPrivilege`. Those events proved that the session had the rights needed for the simulation.

The missing events were the finding. I did not find Event ID `4688` for `mimikatz.exe`, and I did not find Event ID `4656` or `4663` showing access to `lsass.exe`. Live observation showed the tool ran, but the default log did not preserve the process and LSASS-access evidence an analyst would want.

## Response notes

The runbook decision is to preserve first, then interpret. Capture volatile data, acquire and hash the image, review network evidence with encryption limits in mind, analyze persistence offline, and treat missing telemetry as an engineering task. The controls I would add are process-creation auditing with command-line capture, Sysmon, LSASS access auditing where practical, Credential Guard, Defender ASR protection for LSASS, and EDR behavior monitoring.
