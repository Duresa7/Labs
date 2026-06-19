# AWS - VPC networking

The VPC lab was the one that mapped most directly onto how I already think about networks. Building a virtual private cloud is the same segmentation problem as my home network, public versus private, what routes where, what is allowed in, just expressed in AWS primitives instead of VLANs and zones.

## The build

I built a VPC from an address block and carved it into subnets by exposure:

- A **VPC** with a `/16` (for example `10.0.0.0/16`), the private address space everything else lives inside.
- A **public subnet** (`10.0.1.0/24`) for things that need to face the internet, a load balancer or a bastion.
- A **private subnet** (`10.0.2.0/24`) for things that should not, application servers and databases.

A subnet is "public" only because of how it routes, so the routing is the real work:

- An **internet gateway** attached to the VPC is the door to the internet.
- The **public subnet's route table** sends `0.0.0.0/0` to that gateway, which is what makes it public.
- The **private subnet's route table** sends `0.0.0.0/0` to a **NAT gateway** instead, so instances there can reach out (for updates) but cannot be reached inbound.

That NAT-versus-IGW split is the whole public/private distinction. A host in the private subnet can pull a patch; nothing on the internet can open a connection to it.

## Two firewalls, not one

AWS gives you two filtering layers in a VPC, and the lab made the difference concrete:

| | Security group | Network ACL |
|---|---|---|
| Scope | per instance (its ENI) | per subnet |
| State | stateful (return traffic auto-allowed) | stateless (must allow both directions) |
| Rules | allow only | allow and deny |
| Evaluation | all rules | numbered, in order |

The practical consequence is that security groups do most of the day-to-day work, attach one to an instance, allow `443` in, and the response goes back out without a second rule. NACLs sit at the subnet edge as a coarser backstop, and being stateless they need explicit rules for both directions, which is the classic trap: open `443` inbound and forget the ephemeral-port range outbound, and the replies never leave.

## Why it carried over

The reflexes from my [on-prem network](https://github.com/Duresa7/Network-Lab) transferred directly: put the exposed thing in the segment that can reach the internet, put everything else where it cannot, and make the route table, not a label, decide which is which. The names change from VLAN and zone to subnet and security group; the design question, what is allowed to talk to what, does not.
