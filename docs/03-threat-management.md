# 03 - Threat management

Segmentation decides what can talk to what. This layer decides whether the traffic that is allowed is itself hostile. It runs on the gateway's CyberSecure feature set (the base tier; the Proofpoint/Cloudflare-enhanced upgrade is available but I have not turned it on).

## Intrusion prevention

The IPS runs in **notify and block** mode, so a signature match drops the packet rather than just logging it. It inspects five segments: Management, Trusted, IoT, DMZ, and Secure. Signatures update on their own; the last refresh I recorded was current to within a day.

I enable the rulesets by category rather than turning the whole catalog on, which keeps the false-positive noise down on a home link:

| Category | Enabled / available |
|---|---|
| Botnets and threat intelligence | 5 / 5 |
| Viruses, malware, spyware | 4 / 4 |
| Hacking and exploits | 5 / 5 |
| Peer-to-peer and dark web | 2 / 3 |
| Attacks and reconnaissance | 7 / 7 |
| Protocol vulnerabilities | 11 / 12 |

Three hosts are excluded from inspection: the first VPN client lease, one host on the Secure VLAN, and the AD DNS server. Those are places where deep inspection caused more trouble than it caught, so I carved them out deliberately rather than loosening the whole policy.

## Honeypots

I run three decoy hosts, one each on the Management, DMZ, and IoT segments, all sitting at `.2`. They serve nothing real. Anything that connects to them is either a scan or lateral movement, because no legitimate device has a reason to reach them. They are the cheapest tripwire I have: a single alert on one of those addresses tells me something on that segment is looking around.

## DNS filtering and app control

Two DNS-based content-filtering profiles handle category blocking (adult content and advertising) with safe-search enforced for the search engines, applied to selected client groups rather than the whole network. A separate app-control rule blocks online games for one client group on an always-on schedule. None of this is security in the IPS sense; it is policy enforcement at the resolver, and it keeps that enforcement off the endpoints themselves.

## Edge controls

Two more settings sit at the perimeter:

- **Region blocking** drops traffic to and from North Korea and Iran in both directions. Nothing I host has a reason to exchange packets with either, so blocking the regions removes a slice of background noise and a class of inbound probes.
- **Encrypted DNS** is on, resolving over Cloudflare and Google, so the gateway's own lookups are not sent in clear text.

Flow logging is set to capture all traffic plus gateway DNS, and logs are kept locally for 30 days. The gateway can export to a remote syslog or SIEM target; I have that path available but route the security telemetry through the Wazuh agents instead (see [chapter 02](02-firewall-policies.md), policies 8 and 9).
