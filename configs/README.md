# Configs

Sanitized reference artifacts that back the projects. Addresses, keys, and names are placeholders; the structure is what I actually run.

| File | What it is |
|---|---|
| `switch-baseline.cfg` | The IOS-style baseline I bring a switch up with: VLANs, a pruned trunk, SSH-only management, no Telnet. Backs [segmentation](../projects/01-segmentation-and-zoning/README.md) and [the switch-and-router build](../projects/06-switch-and-router-build/README.md). |
| `wireguard-server.example.conf` | The shape of the Management Access WireGuard server from [remote access](../projects/04-wireguard-remote-access/README.md), with keys redacted. The routing is the point, not the crypto. |
| `proxmox-zero-access.fw` | The default-deny host firewall group from [the hypervisor host firewall](../projects/05-hypervisor-host-firewall/README.md): SSH and GUI locked to named sources, dropped for everyone else. |

These are illustrative baselines, not drop-in configs. Read them before adapting anything.
