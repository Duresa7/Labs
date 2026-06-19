# 05 - Switching

The switching layer is where the VLAN design becomes physical. Three switches carry the segments from [chapter 01](01-segmentation.md) to the right ports, and one custom trunk profile is the reason a single cable can feed a hypervisor running a dozen VLANs without handing it the ones it should never see.

## Port profiles

| Profile | Mode | Native VLAN | Tagged VLANs | PoE | Notes |
|---|---|---|---|---|---|
| Management | trunk | Management | all | auto | default uplink between switches |
| Trusted | access | Trusted (10) | none | auto | a wall port for a personal device |
| IoT | access | IoT (20) | none | auto | a wall port for smart-home gear |
| Hypervisor trunk | custom trunk | none | selected only | off | the link to the hypervisor host |

The first three are ordinary. The interesting one is the hypervisor trunk.

## The selective hypervisor trunk

The hypervisor runs VMs on the server-side VLANs, so its uplink has to be a trunk. But a plain "trunk all" would also deliver the user, IoT, and DMZ-edge VLANs to a host that has no business bridging them. So the profile is built as a custom trunk that carries only the VLANs the VMs actually use and excludes the rest:

- **Carried:** Personal-A (40), Secure Client (60), AD-SERVERS (65), MGMT-A (70), SERVERS-A (80), DMZ-A (90)
- **Excluded:** Management, Trusted (10), IoT (20), DMZ (30), Secure (50), AD-ENDUSER (66)

That keeps the hypervisor's bridge surface to exactly the segments its guests live on. If a VM is compromised, the host cannot be used as a path onto the IoT or Trusted VLANs, because those tags never reach the cable.

## Power and resiliency

The downstream switch and the access point are PoE-powered off the core switch, which lets me use the gateway's device supervisors as a watchdog. Each supervised device sends a heartbeat every minute; if it goes silent past a 15-minute threshold, the switch power-cycles its PoE port automatically.

| Supervised device | Powered by | Port | Heartbeat | Silence threshold |
|---|---|---|---|---|
| access-switch-01 | core-switch | 15 | 1 min | 15 min |
| ap-01 | core-switch | 5 | 1 min | 15 min |

It is a small thing, but a hung AP or a wedged downstream switch recovers on its own instead of waiting for me to notice and walk over to it. MC-LAG and switch stacking are not configured; at this scale the daisy-chain in the [README topology](../README.md#physical-topology) is simpler to reason about than a stacked core would be.
