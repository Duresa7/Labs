# 08 - Fundamentals

The network in the earlier chapters did not start as a zone-based firewall and a selective trunk. It started with the basics: addressing a network by hand, building small switch-and-router topologies until the configuration stopped being a mystery, and learning to find the one wrong line that breaks connectivity. This chapter is that foundation, because it is the reason the rest holds together.

## Subnetting

Before I trusted myself to carve up a real network, I did the arithmetic until it was automatic: taking an address block, splitting it into subnets of different sizes, and working out the network address, the usable host range, and the broadcast for each. Variable-length masks are where it gets real, fitting a 50-host segment, a 6-host point-to-point link, and a 2-host link into one block without wasting space or overlapping.

The `/24`-per-VLAN scheme in [chapter 01](01-segmentation.md) is the simple end of that skill. Every segment gets a clean `/24` because the address space is not the constraint here; readability is. But the reason I can look at a subnet and know its range, its gateway, and where it stops without reaching for a calculator is the practice I put in first.

## Switch-and-router builds

I built a series of small topologies in a network simulator to get the device configuration under my hands: two or three switches, a router, several VLANs, and end hosts that had to reach each other and the outside.

The recurring pieces were the same ones the home network uses now:

- creating VLANs and assigning access ports to them
- configuring trunk links and pruning the allowed VLAN list, the same idea as the hypervisor trunk in [chapter 05](05-switching.md)
- inter-VLAN routing so segments could reach each other only where intended
- setting default gateways and verifying end-to-end reachability

Doing it in a simulator meant I could break things on purpose and rebuild them, which is harder to justify on live gear that the rest of the house depends on.

## Securing device access

A switch or router with a default login is a switch or router anyone can own. The builds always ended the same way: an `enable secret`, passwords on the console and VTY lines, local user accounts, and SSH turned on with Telnet turned off so management traffic was not crossing the wire in clear text. That habit is the small-scale version of the default-deny posture in [chapter 07](07-host-firewall.md), set the secure path up first, then close the insecure one.

## Troubleshooting

The most useful drill was fixing a topology I did not build. Given a network that "should work" but does not, the routine is always narrowing: confirm physical and link state, check that the ports are in the VLANs they claim to be, check that the trunk actually carries those VLANs, check the gateway and the routing, and walk it with `ping` and `traceroute` until the break shows itself. More than once the answer was a single VLAN left off a trunk's allowed list, which is exactly the kind of mistake the explicit trunk profile in chapter 05 is designed to make visible.
