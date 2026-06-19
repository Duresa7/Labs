# 02 - Firewall policies

The zone model in [chapter 01](01-segmentation.md) only describes trust. This chapter is the rule set that enforces it. I run seventeen user-defined zone-based policies on top of the gateway's built-in zone matrix. Lower index numbers evaluate first; I keep my "allow" rules in the `10000` band and my explicit "block" rules in the `40000` band, so the early allows carve out the few paths that should exist and the late blocks slam the rest shut.

## The policy set

| # | Name | Action | Source | Destination | Proto / port | Log |
|---|---|---|---|---|---|---|
| 1 | Identity sync connection | allow | External | Gateway | tcp / 9543 | no |
| 2 | VPN to Lab-Mgmt | allow | Vpn | Lab-Mgmt | any | no |
| 3 | VPN to Lab-Servers | allow | Vpn | Lab-Servers | any | no |
| 4 | Lab-Mgmt to Lab-Servers | allow | Lab-Mgmt | Lab-Servers | any | no |
| 5 | Internal to Lab-Mgmt | allow | Internal | Lab-Mgmt | any | no |
| 6 | Internal to Lab-Servers | allow | Internal | Lab-Servers | any | no |
| 7 | DMZ edge to app tier | allow | Dmz (edge-01 only) | Lab-Servers (VLAN 80) | tcp | yes |
| 8 | App tier to SIEM | allow | Lab-Servers | Lab-Mgmt host 10.70.0.20 | tcp / 1514,1515 | no |
| 9 | DMZ edge to SIEM | allow | Dmz (edge-01 only) | Lab-Mgmt host 10.70.0.20 | tcp / 1514,1515 | yes |
| 10 | Mgmt to DMZ monitoring | allow | Lab-Mgmt | Dmz host 10.90.0.10 | tcp / 9100 | yes |
| 11 | App tier to container edge | allow | Lab-Servers | Internal host 10.40.0.35 | tcp / 8000,9443 | yes |
| 12 | DMZ allow-list | allow | Internal (selected clients) | Dmz | any | no |
| 13 | Admin devices to lab VMs | allow | Internal (selected clients) | Personal-A (VLAN 40) | any | no |
| 14 | Admin devices to hypervisor | allow | Internal (selected clients) | Lab-Mgmt | tcp / 22,8006 | no |
| 15 | Block Trusted to lab VMs | block | Trusted (VLAN 10) | Personal-A (VLAN 40) | any | no |
| 16 | Block DMZ to Internal | block | Dmz | Internal | any | no |
| 17 | Block DMZ to LAN | block | Dmz | Internal | any | no |

A few of these are worth calling out. Policies 8 and 9 send Wazuh agent traffic (`1514/1515`) from the app tier and the edge host straight to the SIEM, so logs flow up to the management plane without opening anything else. Policy 7 is the only path from the edge into the app tier, it is pinned to the single edge host, and it is logged. Policies 16 and 17 are the backstop: the DMZ can talk to its specific allowed destinations and nothing else, and it can never reach the Internal zone.

## Who can reach what

This is the same rule set read as a matrix. Empty cells mean the built-in zone behavior applies (and for DMZ-to-Internal, that the explicit blocks win).

| From \ To | Lab-Mgmt | Lab-Servers | Dmz | Internal |
|---|---|---|---|---|
| Vpn | all | all | - | - |
| Internal | all, plus 22/8006 | all | allow-list clients | intra-zone (Trusted to lab VMs blocked) |
| Lab-Mgmt | - | all | 9100 to .90.10 | - |
| Lab-Servers | 1514/1515 to .70.20 | - | - | 8000/9443 to .40.35 |
| Dmz | edge host: 1514/1515 | edge host: VLAN 80 | - | blocked |

## How I think about it

I build the rule set from the management plane outward. The hardest thing to reach is `Lab-Mgmt`: only the VPN, the Internal zone, and the app tier (on two SIEM ports) get in, and only a short list of admin clients can hit SSH and the hypervisor GUI on `22/8006`. The app tier is allowed to reach the SIEM and the container edge agent, nothing more. The edge gets two pinholes, both logged, both scoped to one host. Everything the rules do not name falls through to the zone defaults and the two DMZ block rules.

Two design choices keep this honest. First, the cross-tier allows target a host and a port, not a zone and "any", wherever I can manage it; policy 10's single `9100` to one DMZ host is the pattern I aim for. Second, the rules I most want to see in the logs (the edge crossing into the app tier and the SIEM) are the ones with logging on, so the noisy intra-Internal traffic stays quiet and the boundary crossings stand out.
