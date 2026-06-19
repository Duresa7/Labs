# AWS custom VPC and web server

This is the cloud-networking project everything else builds on. I started from an empty region and built a virtual private cloud up to a working web server that the internet could reach: a VPC with its own address space, a public and a private subnet, routing, a security group, and an EC2 instance serving a page. It is the cloud version of the segmentation and edge work I do on my [home network](https://github.com/Duresa7/Network-Lab), and doing it by hand is what made the pieces click.

## The target architecture

```mermaid
flowchart TD
    NET["Internet"]
    IGW["Internet gateway"]
    subgraph vpc["lab-vpc  10.0.0.0/16"]
        direction TB
        PUB["public subnet 10.0.10.0/24 (us-east-1a)<br/>Web Server EC2 + public IP"]
        PRIV["private subnet 10.0.20.0/24 (us-east-1b)<br/>no inbound from internet"]
    end

    NET --- IGW
    IGW --- PUB
```

The split is the whole point: the public subnet has a path to the internet, the private subnet does not. What you put where decides what is reachable, before any firewall rule is written.

## Building the VPC

In the `us-east-1` (N. Virginia) region, I created the VPC with a `10.0.0.0/16` address space, which leaves room for plenty of `/24` subnets inside it. I enabled DNS hostnames and DNS resolution so instances get resolvable names, and left tenancy default.

Then two subnets in different availability zones, so the design can survive one AZ going down:

| Subnet | CIDR | AZ | Role |
|---|---|---|---|
| lab-subnet-public | 10.0.10.0/24 | us-east-1a | internet-facing |
| lab-subnet-private | 10.0.20.0/24 | us-east-1b | internal only |

A `/24` out of a `/16` gives each subnet 251 usable addresses after AWS reserves five, which is the kind of subnetting arithmetic I work through by hand in my [network lab](https://github.com/Duresa7/Network-Lab/blob/main/projects/07-ipv4-addressing-design/README.md).

## Routing: what makes a subnet "public"

A subnet is not public because of its name; it is public because its route table sends unknown traffic to an internet gateway. I attached an **internet gateway** to the VPC, then worked with the route tables:

- **lab-rtb-public** carries a route for `0.0.0.0/0` pointing at the internet gateway, and I associated the public subnet with it. That single route is what lets the web server answer traffic from the internet.
- **lab-rtb-private** has no such route, so the private subnet's traffic has nowhere to go but inside the VPC.

Associating the right subnet with the right route table is the step people skip and then wonder why their instance is unreachable. The console confirmed the association applied to the public route table.

## The security group

With routing in place, the security group decides which ports are open. I created **Web Security Group** with one inbound rule:

| Type | Protocol | Port | Source |
|---|---|---|---|
| Web (HTTPS) | TCP | 443 | 0.0.0.0/0 |

Source `0.0.0.0/0` means anyone, which is correct for a public web server and wrong for almost anything else. A security group is stateful, so the matching return traffic is allowed automatically and I did not need an outbound rule for replies. This is the cloud analogue of a firewall policy: the route table gets the packet to the subnet, the security group decides whether the instance accepts it.

## Launching the web server

The EC2 instance pulled it together:

- **AMI:** Amazon Linux 2023
- **Type:** t2.micro
- **Network:** the `lab-vpc`, in `lab-subnet-public`
- **Auto-assign public IP:** enabled (so it gets a routable address)
- **Security group:** the existing Web Security Group
- **Storage:** an 8 GiB gp3 root volume
- **User data:** a boot script that installed and started the web server, so the instance came up already serving a page rather than needing me to log in and configure it

Auto-assigning the public IP plus the public subnet's route to the gateway is what made it reachable; a script in user data is what made it useful the moment it booted.

## Verifying it worked

The lab's grader checked six things, and all six passed for a total of 30 out of 30: the VPC was created correctly, the subnets were created correctly, the subnet-to-route-table association was right, the security group was right, the EC2 instance was created correctly, and the instance's website was reachable over the internet. That last check is the real one. A page loading from the instance's public address proves the entire chain at once: the gateway, the public route, the subnet placement, the public IP, and the security group all had to be correct together for a single HTTP response to come back.

## What it maps to

Every piece here has a counterpart in network design I already understood, which is why building it cemented the cloud model:

| AWS construct | What it is, in plain terms |
|---|---|
| VPC | your own private network with its own address space |
| Subnet | a segment of that space, pinned to an availability zone |
| Route table | the routing decision that makes a subnet public or private |
| Internet gateway | the edge router to the public internet |
| Security group | a stateful, instance-level firewall |

The private subnet sitting there with no route out is the same instinct as the management tier on my home network: the most protected place is the one with no path to the outside, and you only open a path when something has a reason to need it.
