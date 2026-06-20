# Scan command reference

The exact nmap commands I ran against the target (`192.168.10.4`) from the Kali box (`192.168.10.6`), one open port (`22`) and one closed port (`3389`) per scan, each captured in Wireshark with the display filter `ip.addr==192.168.10.6 && ip.addr==192.168.10.4`. nmap 7.95.

```bash
# TCP connect scan (completes the 3-way handshake)
nmap -sT -p 22   192.168.10.4
nmap -sT -p 3389 192.168.10.4

# SYN / stealth scan (half-open; default)
nmap -sS -p 22   192.168.10.4
nmap -sS -p 3389 192.168.10.4

# FIN scan
nmap -sF -p 22   192.168.10.4
nmap -sF -p 3389 192.168.10.4

# NULL scan (no flags set)
nmap -sN -p 22   192.168.10.4
nmap -sN -p 3389 192.168.10.4

# Xmas scan (FIN, PSH, URG)
nmap -sX -p 22   192.168.10.4
nmap -sX -p 3389 192.168.10.4

# OS fingerprint + open-port inventory
nmap -O 192.168.10.4
```

## How to read the result

| Reply observed | Meaning |
|---|---|
| `SYN, ACK` (on `-sT` / `-sS`) | port **open** |
| `RST, ACK` | port **closed** |
| no reply (on `-sF` / `-sN` / `-sX`) | **open or filtered** (standards-compliant stacks stay silent) |

The FIN/NULL/Xmas behavior relies on RFC 793 semantics, so it distinguishes open from closed on Unix-like targets but not on Windows, which does not follow that behavior. The walkthrough and the captured packets are in the [project README](README.md).
