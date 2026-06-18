# Chapter 05 - Attack and defend

> **Scope and ethics.** Everything here was run against my own lab domain, on an isolated network segment I control, from the `kali-pen` VM. Nothing in this chapter touches a network or system I do not own. Offensive tooling is shown so the defensive results mean something. Do not point any of it at systems you are not authorized to test.

## Objective

Hardening you cannot attack is just a checklist. The point of this pass is to take the controls from [chapter 02](02-gpo-security-hardening.md) and try to walk through them from `kali-pen`, then write down two things for each step: did the control hold, and where it did not, what I changed to close the gap.

The full chain and the control that stops each step is in [diagrams/attack-chain.md](../diagrams/attack-chain.md). The Kali commands are in [scripts/attack-defend/attack-chain.sh](../scripts/attack-defend/attack-chain.sh); the blue-team checks are in [scripts/attack-defend/blue-team-verification.ps1](../scripts/attack-defend/blue-team-verification.ps1).

## The pass

### Recon

```bash
nmap -sV -p 53,88,135,139,389,445,464,636,3268 10.10.10.0/24
enum4linux-ng -A 10.10.10.10
nxc smb 10.10.10.10
```

Standard DC fingerprint: Kerberos, LDAP, SMB, DNS. SMB null-session enumeration is limited, and `nxc` flags that **SMB signing is not required**. That last line is the first finding.

### LLMNR / NBT-NS poisoning

```bash
sudo responder -I eth0 -wv
```

Responder answered broadcast name lookups and captured a `NetNTLMv2` hash from a mistyped share path. This **succeeded**, which means name-resolution poisoning was a real gap. It is the second finding, and combined with the missing SMB signing it opens the door to an NTLM relay.

### Password spray

```bash
kerbrute userenum  -d corp.local --dc 10.10.10.10 users.txt
kerbrute passwordspray -d corp.local --dc 10.10.10.10 users.txt 'Spring2026!'
```

This is where the hardening bit back. The spray tripped the account-lockout policy (`GPO-PasswordPolicy`: 5 attempts, 30-minute lockout) almost immediately, and every lockout wrote a `4740` event on the DC. A spray that would run quietly against an unhardened domain turned into noise and locked accounts.

### Kerberoasting and AS-REP roasting

```bash
GetUserSPNs.py corp.local/jack-user -dc-ip 10.10.10.10 -request
GetNPUsers.py corp.local/ -dc-ip 10.10.10.10 -usersfile users.txt -no-pass
```

Both came back nearly empty. There are no service accounts carrying SPNs with guessable passwords (the `Service-Accounts` OU is empty by design), and no account has Kerberos pre-authentication disabled, so there is nothing to AS-REP roast. The OU and account model from [chapter 01](01-onprem-ad-build.md) is what made this a dead end.

### Graph the domain with BloodHound

```bash
bloodhound-python -d corp.local -u jack-user -p '<lab-pw>' -c All -ns 10.10.10.10
```

The graph is short. `jack-user` and `test-user-1` have no path to Domain Admin. Only `acarter` is privileged, and it lives in its own OU and is not used for daily logon. The "shortest path to Domain Admins" query returns nothing useful from a managed user. Minimal privilege is boring on a BloodHound graph, which is the goal.

### Credential dumping and cached-credential reuse

These assume an attacker already has local admin on a managed workstation, which the hardening does not give them (local Administrators is restricted to Domain Admins). Granting it for the test anyway:

```text
mimikatz # privilege::debug
mimikatz # sekurlsa::logonpasswords
```

LSASS is a protected process (`RunAsPPL = 1`), so `sekurlsa::logonpasswords` is refused. And because `CachedLogonsCount = 0`, there is no cached verifier to pull for offline cracking. The two settings from [chapter 02](02-gpo-security-hardening.md) shut both techniques.

## Findings and what I changed

| Finding | Severity | Fix |
|---|---|---|
| LLMNR / NBT-NS poisoning captured a hash | High | Added a GPO to turn off multicast name resolution, and disabled NetBIOS over TCP/IP |
| SMB signing not required (NTLM relay risk) | High | Enforced SMB signing on clients and servers by GPO |
| Password spray | Mitigated already | Lockout policy held; added alerting on `4740` |
| Kerberoast / AS-REP | Not exploitable | Account and OU model already prevents it |
| Credential dump / cached reuse | Blocked already | LSA protection and zero cached logons held |

The two real gaps got remediation GPOs:

```powershell
# Turn off LLMNR (multicast name resolution)
Set-GPRegistryValue -Name "GPO-ManagedWorkstations-Security" `
  -Key "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient" `
  -ValueName "EnableMulticast" -Type DWord -Value 0

# Require SMB signing, client and server
Set-GPRegistryValue -Name "GPO-ManagedWorkstations-Security" `
  -Key "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
  -ValueName "RequireSecuritySignature" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-ManagedWorkstations-Security" `
  -Key "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters" `
  -ValueName "RequireSecuritySignature" -Type DWord -Value 1
```

Re-running Responder and `nxc` after the GPO applied: the poisoning no longer returns a hash, and `nxc` reports SMB signing as required.

## Verification & evidence

The blue-team side is read from the DC event log, where the attacks left tracks.

```powershell
# Failed logons from the spray
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50

# Account lockouts triggered by the spray
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740}

# Kerberos service-ticket requests (the Kerberoast attempt)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4769} -MaxEvents 50
```

> **Screenshot slot:** BloodHound showing no path from a managed user to Domain Admins. Save to `evidence/screenshots/05-bloodhound.png`.

> **Screenshot slot:** Event Viewer with the `4740` lockout events from the spray. Save to `evidence/screenshots/05-lockout-events.png`.

> **Screenshot slot:** Responder returning nothing after the LLMNR fix. Save to `evidence/screenshots/05-responder-after.png`.

## What this proves

A red-team pass run against my own domain, end to end: recon, poisoning, spray, Kerberoast, BloodHound, and credential dumping, each mapped to the control that stopped it or to the gap it exposed. The valuable part is the gaps. LLMNR poisoning and missing SMB signing were real, I found them by attacking the box rather than reading a checklist, and I closed them with GPOs and confirmed the fix by re-running the attack. That loop, attack to find it, defend to close it, verify it is closed, is the whole point of the lab.
