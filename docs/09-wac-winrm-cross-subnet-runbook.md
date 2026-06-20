# Chapter 09 - WAC and WinRM across subnets

This was a small troubleshooting runbook from the AD build: Windows Admin Center
could not connect from a non-domain admin workstation to a domain controller on
another subnet. The fix was not a new tool. It was making WinRM explicit on both
ends, then scoping the firewall rule to one admin IP instead of opening it
wide.

## Environment

| Component | Value |
|---|---|
| Admin workstation | `10.10.30.50` |
| Domain controller | `CORP-DC01`, `10.10.10.10` |
| Domain | `corp.local` |
| Windows Admin Center | v2 |
| Workstation domain state | Not domain joined |
| WinRM transport | HTTP on TCP `5985` |

The important constraint was authentication. Because the workstation was not
domain joined, Kerberos was not available. I had to trust the DC target locally
and use Negotiate so NTLM could carry the credential exchange.

## Failure

Windows Admin Center reported the domain controller as unreachable over WinRM.
The root causes were all ordinary, which made the fix easy to miss:

- WinRM was not fully enabled on the DC.
- The predefined WinRM firewall rules were not active.
- The Public-profile WinRM rule was still scoped to local subnet traffic.
- The non-domain workstation did not have the DC in TrustedHosts.

## Fix

On the admin workstation, I added the DC to TrustedHosts and restarted WinRM:

```powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.10.10.10" -Force
Restart-Service WinRM -Force
```

On the domain controller, I enabled the predefined Windows Remote Management
inbound rules:

```text
Windows Remote Management (HTTP-In) - Domain, Private
Windows Remote Management (HTTP-In) - Public
```

The Public-profile rule was the key detail. Its default scope did not allow the
admin subnet, so I changed the remote IP scope to the single admin workstation:

```text
Remote IP allowed on Public WinRM rule: 10.10.30.50
```

I left the legacy compatibility rule disabled. WAC only needed WinRM on `5985`,
not the old compatibility listener.

## Verification

I checked transport first:

```powershell
Test-NetConnection -ComputerName 10.10.10.10 -Port 5985
```

The expected result was:

```text
TcpTestSucceeded : True
```

Then I checked WSMan authentication:

```powershell
Test-WSMan -ComputerName 10.10.10.10 -Authentication Negotiate -Credential (Get-Credential)
```

The server returned the normal WSMan identity response with Microsoft as the
vendor and Windows Server 2025 as the OS family. After that, I added the server
in Windows Admin Center using an explicit admin credential:

```text
CORP\Administrator
```

## What I Kept Tight

I did not solve this by making WinRM broad. The final state was:

| Decision | Why |
|---|---|
| TrustedHosts contains the DC IP only | The workstation was not domain joined, so it needed a narrow NTLM trust target. |
| Public WinRM rule scoped to `10.10.30.50` | Cross-subnet management worked without allowing every remote address. |
| WinRM compatibility port left disabled | WAC did not need it. |
| DCs added individually in WAC | Domain controllers are not a Windows Failover Cluster. |

This is the kind of fix I like keeping as a chapter because the lesson is
small and reusable: make the trust path explicit, make the firewall scope
narrow, then verify the port before blaming the management tool.
