# IPv4 addressing design

Every segmented network is an addressing problem first. Before I could lay out twelve VLANs or hand a router the right interface addresses, I had to be fluent in carving a block of addresses into right-sized pieces with no waste and no overlap. This project is three variable-length subnetting (VLSM) designs worked end to end, plus the analysis method I use to read any address and prefix on sight. These are the calculations behind [the switch-and-router build](../06-switch-and-router-build/README.md) and behind the `/24`-per-VLAN choices in [the segmentation design](../01-segmentation-and-zoning/README.md).

## The method

VLSM means allocating subnets of different sizes from one block, sized to each group's host count. The discipline that keeps it clean:

1. **List the requirements largest first.** Big subnets allocated first avoids stranding a large group in a gap.
2. **Round each host count up to a power of two**, remembering two addresses per subnet are spent on the network and broadcast. A group of 30 needs 32 addresses (a `/27`), not 30.
3. **Allocate contiguously**, each new subnet starting where the last one's broadcast left off.
4. **Record network, first host, last host, broadcast, and mask** for each, because those five values are what you configure.

## Design 1: subnet a /24 for 30 hosts, then re-subnet for 14

Starting block `172.16.10.0/24`, each subnet to hold 30 hosts; then take the fourth subnet and split it again for 14 hosts. The source worksheet used a non-home lab block; I rewrote it to this private documentation block before publishing.

30 hosts rounds to 32 addresses, a `/27` (mask 255.255.255.224):

| Subnet | Network | Range | Broadcast |
|---|---|---|---|
| 1 | 172.16.10.0/27 | .1 - .30 | .31 |
| 2 | 172.16.10.32/27 | .33 - .62 | .63 |
| 3 | 172.16.10.64/27 | .65 - .94 | .95 |
| 4 | 172.16.10.96/27 | .97 - .126 | .127 |

Now re-subnet the fourth block (`172.16.10.96/27`) for 14 hosts. 14 rounds to 16 addresses, a `/28` (mask 255.255.255.240):

| Sub-subnet | Network | Range | Broadcast |
|---|---|---|---|
| 4a | 172.16.10.96/28 | .97 - .110 | .111 |
| 4b | 172.16.10.112/28 | .113 - .126 | .127 |

The `/27` that held 30 became two `/28`s holding 14 each, with no address outside the original `172.16.10.96/27` touched.

## Design 2: a support center, five departments from a /25

Block `10.50.0.0/25` (128 addresses), split for: Customer Service 28, IT 10, Managers 8, Admin 6, Front desk 2. The raw worksheet mixed one prompt row with a different completed table, so I treated the public version as a cleaned design exercise and sized each department from the stated host requirement.

Largest first:

| Department | Hosts needed | Size | Network | Range | Broadcast | Mask |
|---|---|---|---|---|---|---|
| Customer Service | 28 | /27 (32) | 10.50.0.0/27 | .1 - .30 | .31 | 255.255.255.224 |
| IT | 10 | /28 (16) | 10.50.0.32/28 | .33 - .46 | .47 | 255.255.255.240 |
| Managers | 8 | /28 (16) | 10.50.0.48/28 | .49 - .62 | .63 | 255.255.255.240 |
| Admin | 6 | /29 (8) | 10.50.0.64/29 | .65 - .70 | .71 | 255.255.255.248 |
| Front desk | 2 | /30 (4) | 10.50.0.72/30 | .73 - .74 | .75 | 255.255.255.252 |

Everything fits below `.75`, well inside the `/25` that ends at `.127`, leaving `.76 - .126` available for growth. The interesting correction is Managers: eight usable hosts cannot fit in a `/29`, because a `/29` has only six usable addresses after network and broadcast. It needs the same `/28` size as a ten-host group.

## Design 3: a large building, three populations from a /21

The source prompt gave a `/24`, but the stated host counts cannot fit in 256 addresses. I handled that as a design check: find the smallest aligned block that can hold support staff 250, engineering staff 300, and client endpoints 1000 without overlap. A `/21` (`10.10.8.0/21`, 2048 addresses) is the smallest aligned block that covers the completed allocation shape.

| Group | Hosts needed | Size | Network | Range | Broadcast |
|---|---|---|---|---|---|
| Client endpoints | 1000 | /22 (1024, 1022 usable) | 10.10.12.0/22 | 10.10.12.1 - 10.10.15.254 | 10.10.15.255 |
| Support staff | 250 | /23 (512, 510 usable) | 10.10.8.0/23 | 10.10.8.1 - 10.10.9.254 | 10.10.9.255 |
| Engineering staff | 300 | /23 (512, 510 usable) | 10.10.10.0/23 | 10.10.10.1 - 10.10.11.254 | 10.10.11.255 |

The three allocations tile the `/21`: client endpoints take the top half, and the two staff groups split the bottom half. This is the same shape as carving the home network's address space into per-VLAN `/24`s, with bigger blocks.

## Reading an address on sight

The other half of the skill is going the other way: given an address and prefix, state its network, broadcast, mask, and host count without a calculator. The trick is the "block size" in the interesting octet, which is `256 - mask-octet`.

Worked example, `172.31.5.89/27`:

- `/27` puts 3 host bits in the fourth octet; mask is `255.255.255.224`.
- Block size in the fourth octet is `256 - 224 = 32`. Networks fall on multiples of 32: `.0, .32, .64, .96 ...`
- `.89` lands in the `.64` block, so the network is `172.31.5.64`, the broadcast is the next boundary minus one (`.95`), and the usable range is `.65 - .94`.
- Host count is `2^3 - 2 = 6`... no: `2^(32-27) - 2 = 30` usable.

I drilled this across dozens of addresses and prefixes until reading `/26` as "block size 64" or `/30` as "block size 4, two usable, a point-to-point link" was immediate. That fluency is what lets the rest of the network design move quickly: when I assign a VLAN a `/24` or hand a router interface the last host of a subnet, the arithmetic is already done in my head.
