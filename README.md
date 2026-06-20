# Cybersecurity Lab

Both sides of security in one place: the defensive work I do to detect, investigate, and respond, and the offensive work I do to understand the attacks I am defending against. They belong together. You cannot tune a detection for a technique you have never run, and there is no point running an attack you cannot then catch. Every offensive project here ends on the control that stops it, and every defensive project is built on an artifact I captured, wrote, or verified.

The centerpiece of the defensive side is a real incident-response record I wrote when a vendor I depend on (Vercel) disclosed a security incident, presented the way an IR record should be: scoped, with a risk assessment, the actions taken, verification that they worked, residual risk, and follow-ups.

> **Scope and authorization.** The offensive work was done in isolated, host-only virtual lab networks, against machines I built or was explicitly authorized to test (a Kali attacker against a deliberately vulnerable target VM). None of it touches systems I do not control. The write-ups describe method and outcome; they stop short of reusable shellcode and live targets. The point is understanding, not a copy-paste attack kit.

## Defensive

| Project | What it covers |
|---|---|
| [01 - Vendor breach incident response](projects/defensive/01-vendor-breach-incident-response/README.md) | A real credential-rotation and access-review response to a vendor's disclosed breach, written as a full IR record |
| [02 - DFIR investigation](projects/defensive/02-dfir-investigation/README.md) | Live response in order of volatility, forensic disk imaging with hash verification, and indicator development |
| [03 - Detection engineering](projects/defensive/03-detection-engineering/README.md) | Writing and testing Snort rules, and a Windows-log investigation that exposed a default detection gap |
| [04 - Vulnerability management and hardening](projects/defensive/04-vulnerability-management-and-hardening/README.md) | Vulnerability scanning, STIG hardening, and scripted Windows patching |
| [05 - Protocol analysis](projects/defensive/05-protocol-analysis/README.md) | What the wire shows: capturing plaintext credentials and proving what encryption hides |
| [06 - Incident case studies](projects/defensive/06-incident-case-studies/README.md) | Structured analyses of real-world breaches, mapped to the response lifecycle and to MITRE ATT&CK |
| [07 - Wazuh SIEM deployment](projects/defensive/07-wazuh-siem-deployment/README.md) | Single-node Wazuh build, Linux agent enrollment, and FIM/SCA/vulnerability visibility across edge and app hosts |
| [08 - Secure WordPress hosting](projects/defensive/08-secure-wordpress-hosting/README.md) | Defense-in-depth hardening for a public WordPress host behind Cloudflare Tunnel, Caddy, WAF rules, 2FA, and backups |
| [09 - Mobile forensics and threat analysis](projects/defensive/09-mobile-forensics-and-threat-analysis/README.md) | A mobile QR-phishing campaign mapped to MITRE ATT&CK, and a Snapchat iOS artifact-forensics methodology (timestamps, media integrity, chain of custody) |
| [10 - OSINT domain triage and IOC reporting](projects/defensive/10-osint-domain-triage-and-ioc-reporting/README.md) | A passive VirusTotal reputation assessment of a set of domains, written up as a formal IOC report with confidence-rated findings and block/sandbox/monitor recommendations |
| [11 - Snort and Splunk detection pipeline](projects/defensive/11-snort-splunk-detection-pipeline/README.md) | A team capstone design: feeding a Snort IDS sensor into Splunk through a Universal Forwarder so raw alerts become searchable, correlated, ATT&CK-mapped triage |

## Offensive

| Project | What it covers |
|---|---|
| [01 - Network recon and port scanning](projects/offensive/01-network-recon-and-port-scanning/README.md) | Every nmap scan type run against a target, captured in Wireshark, with the flag exchange that tells open from closed, plus an OS fingerprint |
| [02 - Stack buffer overflow](projects/offensive/02-stack-buffer-overflow/README.md) | ASLR demonstrated, a vulnerable C program written and overflowed to a controlled crash, and the mitigations that defeat it |
| [03 - Password cracking](projects/offensive/03-password-cracking/README.md) | A hashcat dictionary attack against a mixed set of hashes, why only some fell, and what storage choices stop it |
| [04 - Reverse shell and post-exploitation](projects/offensive/04-reverse-shell-post-exploitation/README.md) | A connect-back shell used to read and write files on a target, why it beats a bind shell, and the egress controls that catch it |
| [05 - Steganography: data hiding](projects/offensive/05-steganography-data-hiding/README.md) | Hiding an encrypted file inside an ordinary image with OpenStego, recovering it, and the entropy and egress controls that catch the channel |

## How the two sides connect

The detections on the defensive side come straight from the offensive side. The Snort rules in [detection engineering](projects/defensive/03-detection-engineering/README.md) catch the exact FIN, NULL, Xmas, and UDP scans I generated in [network recon](projects/offensive/01-network-recon-and-port-scanning/README.md). The same loop runs through the whole repo: do the attack, watch what it looks like on the wire and in the logs, then write the control that closes it.

This sits alongside the rest of my infrastructure work: the [Network-Lab](https://github.com/Duresa7/Network-Lab) it defends, the [Cloud-Lab](https://github.com/Duresa7/Cloud-Lab), and the [Homelab-Project](https://github.com/Duresa7/Homelab-Project).
