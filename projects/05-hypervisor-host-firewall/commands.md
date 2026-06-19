# Proxmox host firewall command reference

How the `zero_access` security group ([../../configs/proxmox-zero-access.fw](../../configs/proxmox-zero-access.fw)) is applied and verified on the cluster with the `pve-firewall` tooling. Addresses are placeholders.

## Where the rules live

Proxmox firewall config is plain text under `/etc/pve/firewall/`:

```bash
# Datacenter-wide security groups and rules
cat /etc/pve/firewall/cluster.fw

# Per-node rules
cat /etc/pve/firewall/<nodename>.fw
```

A security group is defined once at the datacenter level and then referenced from a node or guest, which is how `zero_access` is reused across all three nodes.

## Applying and checking

```bash
pve-firewall compile        # parse the rules and show what would be generated
pve-firewall status         # confirm the firewall is enabled and active
pve-firewall localnet       # show the management network the node trusts
systemctl status pve-firewall
```

`pve-firewall compile` is the equivalent of the Cisco habit of validating a config before relying on it: it catches a malformed rule before it is enforced. After applying `zero_access`, I verify from an allowed host (SSH and the GUI on 8006 succeed) and from a disallowed segment (both refused), which proves the two final `DROP` rules are doing their job. This host firewall is the second yes-vote behind the network firewall; see [README.md](README.md) for why both have to agree.
