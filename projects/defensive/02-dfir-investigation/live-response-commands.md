# Live-response command runbook

The exact commands I ran on the suspected-compromised Windows host, in the order I ran them, with what each one captured and why it comes when it does. The ordering follows the order of volatility: the most fragile evidence first. Output from each was written to a dedicated evidence folder, not left on screen.

```powershell
# 1. Session context -- who am I running as right now
whoami            # -> desktop-hm66ljc\w11-test (the lab VM and its user)

# 2. Network configuration -- addresses, DHCP leases, DNS (changes over time)
ipconfig /all

# 3. Active connections with owning PIDs -- sockets open and close constantly,
#    so capture them before doing anything that opens new ones
netstat -ano

# 4. Running processes -- a malicious process can exit at any moment
tasklist

# 5. Full process detail, including paths and parents.
#    The classic step here is `wmic process list full`, but wmic is deprecated
#    and failed on this host, so I substituted the PowerShell equivalent:
Get-Process | Format-List * > "$env:USERPROFILE\Documents\IR\LiveData\processes.txt"
```

## What each step established

| Step | Command | What it told me |
|---|---|---|
| 1 | `whoami` | the account context the response was running under |
| 2 | `ipconfig /all` | host identity, the single NIC, IPv4 `10.0.2.15/24`, gateway and DNS |
| 3 | `netstat -ano` | an established outbound connection on 443; ran the owning PID down to `svchost` reaching a Microsoft Azure endpoint, so I documented it as benign |
| 4 | `tasklist` | quick process list; captured the simulated `cmd.exe` process that matched the `weirdsvc.bat` activity |
| 5 | `Get-Process \| Format-List *` | full detail with paths and parents; corroborated the command prompt path and start time, and showed no second suspicious process |

The conclusion from live response: the collection caught the simulated suspicious process while it was still live, then narrowed the rest of the investigation to disk and persistence artifacts. Every command above is itself a footprint on the host, so I ran the minimum needed and recorded each one, which is the discipline that keeps a live response from contaminating its own evidence.
