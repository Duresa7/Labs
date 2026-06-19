# 07 - Host firewall

The gateway firewall controls movement between segments. It does not, by itself, decide who may open an SSH session or the management GUI on a hypervisor node. That is enforced a second time at the host, with a default-deny rule on the two ports that matter and an explicit allow-list of the sources that are permitted to reach them.

The whole policy lives in one security group I attach to the cluster, named `zero_access`. It is built bottom-up: the last two rules drop SSH (`22`) and the hypervisor GUI (`8006`) from everyone, and the rules above them re-open those ports only for the sources that should have them.

| Action | Proto | Source | Dest port | Why |
|---|---|---|---|---|
| accept | tcp | 10.40.0.36 (ansible-01) | 22, 8006 | automation host |
| accept | tcp | 10.10.0.27 (admin laptop) | 22, 8006 | my primary workstation |
| accept | tcp | 10.50.0.241 (hardened workstation) | 22, 8006 | secondary admin box |
| accept | tcp | 10.70.0.0/24 | 9100 | Prometheus node_exporter scrape |
| accept | tcp | 10.70.0.0/24 | 8006 | management-tier GUI access |
| accept | any | 10.200.6.0/24 | (mgmt subnet 10.70.0.0/24) | WireGuard admin path |
| accept | any | 10.200.6.0/24 | (server subnet 10.80.0.0/24) | WireGuard to app tier |
| accept | tcp | 10.70.0.10 (grey-server) | 22 | intra-cluster SSH |
| accept | tcp | 10.70.0.11 (purple-server) | 22 | intra-cluster SSH |
| accept | tcp | 10.70.0.12 (blue-server) | 22 | intra-cluster SSH |
| drop | tcp | any | 22 | default-deny SSH |
| drop | tcp | any | 8006 | default-deny GUI |

The allow-list is deliberately short: an automation host, two named admin workstations, the monitoring scrape from the management subnet, the three cluster nodes talking to each other, and the WireGuard subnet from [chapter 04](04-remote-access.md). The node_exporter rule opens only `9100`, the metrics port, not the admin ports, so monitoring never doubles as a way in.

This is the same idea as the gateway's two DMZ block rules, applied one layer down. Even if something reached a node's subnet that the gateway policy did not expect, it would still hit a closed SSH and GUI port unless it came from one of the sources on this list. Two independent layers have to agree before a management session is possible.
