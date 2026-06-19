# IPv4 addressing design

Every segmented network is an addressing problem first. Before I could lay out twelve VLANs or hand a router the right interface addresses, I had to be fluent in carving a block of addresses into right-sized pieces with no waste and no overlap. This project is three variable-length subnetting (VLSM) designs worked end to end, plus the analysis method I use to read any address and prefix on sight. These are the calculations behind [the switch-and-router build](../06-switch-and-router-build/README.md) and behind the `/24`-per-VLAN choices in [the segmentation design](../01-segmentation-and-zoning/README.md).

## The method

VLSM means allocating subnets of different sizes from one block, sized to each group's host count. The discipline that keeps it clean:

1. **List the requirements largest first.** Big subnets allocated first avoids stranding a large group in a gap.
2. **Round each host count up to a power of two**, remembering two addresses per subnet are spent on the network and broadcast. A group of 30 needs 32 addresses (a `/27`), not 30.
3. **Allocate contiguously**, each new subnet starting where the last one's broadcast left off.
4. **Record network, first host, last host, broadcast, and mask** for each, because those five values are what you actually configure.

## Design 1: subnet a /24 for 30 hosts, then re-subnet for 14

Starting block `172.16.10.0/24`, each subnet to hold 30 hosts; then take the fourth subnet and split it again for 14 hosts.

30 hosts rounds to 32 addresses, a `/27` (mask 255.255.255.224):

| Subnet | Network | Range | Broadcast |
|---|---|---|---|
| 1 | 172.16.10.0/27 | .1 - .30 | .31 |
| 2 | 172.16.10.32/27 | .33 - .62 | .63 |
| 3 | 172.16.10.64/27 | .65 - .94 | .95 |
| 4 | 172.16.10.96/27 | .97 - .126 | .127 |

Now re-subnet subnet 4 (`172.16.10.96/27`) for 14 hosts. 14 rounds to 16 addresses, a `/28` (mask 255.255.255.240):

| Sub-subnet | Network | Range | Broadcast |
|---|---|---|---|
| 4a | 172.16.10.96/28 | .97 - .110 | .111 |
| 4b | 172.16.10.112/28 | .113 - .126 | .127 |

The `/27` that held 30 became two `/28`s holding 14 each, with no address outside the original `172.16.10.96/27` touched.

## Design 2: a support center, five departments from a /25

Block `10.50.0.0/25` (128 addresses), split for: Admin 30, Customer Service 14, IT 14, Managers 6, Front desk 6. Largest first:

| Department | Hosts needed | Size | Network | Range | Broadcast | Mask |
|---|---|---|---|---|---|---|
| Admin | 30 | /27 (32) | 10.50.0.0/27 | .1 - .30 | .31 | 255.255.255.224 |
| Customer Service | 14 | /28 (16) | 10.50.0.32/28 | .33 - .46 | .47 | 255.255.255.240 |
| IT | 14 | /28 (16) | 10.50.0.48/28 | .49 - .62 | .63 | 255.255.255.240 |
| Managers | 6 | /29 (8) | 10.50.0.64/29 | .65 - .70 | .71 | 255.255.255.248 |
| Front desk | 6 | /29 (8) | 10.50.0.72/29 | .73 - .78 | .79 | 255.255.255.248 |

Everything fits below `.79`, well inside the `/25` that ends at `.127`, leaving room to grow. Sizing each department to a different mask is the whole value of VLSM: a fixed `/27` for all five would have run out of block after four departments and wasted addresses on the two that only needed six.

## Design 3: a campus building, three populations from a /21

A larger allocation: a `/21` (`10.10.8.0/21`, 2048 addresses) split across Staff 510, Faculty 510, Students 1022.

| Population | Hosts needed | Size | Network | Range | Broadcast |
|---|---|---|---|---|---|
| Students | 1022 | /22 (1024) | 10.10.12.0/22 | 10.10.12.1 - 10.10.15.254 | 10.10.15.255 |
| Staff | 510 | /23 (512) | 10.10.8.0/23 | 10.10.8.1 - 10.10.9.254 | 10.10.9.255 |
| Faculty | 510 | /23 (512) | 10.10.10.0/23 | 10.10.10.1 - 10.10.11.254 | 10.10.11.255 |

The three allocations tile the `/21` exactly: students take the top half, staff and faculty split the bottom half. This is the same shape as carving the home network's address space into per-VLAN `/24`s, just with bigger blocks.

## Reading an address on sight

The other half of the skill is going the other way: given an address and prefix, state its network, broadcast, mask, and host count without a calculator. The trick is the "block size" in the interesting octet, which is `256 − mask-octet`.

Worked example, `172.31.5.89/27`:

- `/27` puts 3 host bits in the fourth octet; mask is `255.255.255.224`.
- Block size in the fourth octet is `256 − 224 = 32`. Networks fall on multiples of 32: `.0, .32, .64, .96 …`
- `.89` lands in the `.64` block, so the network is `172.31.5.64`, the broadcast is the next boundary minus one (`.95`), and the usable range is `.65 - .94`.
- Host count is `2^3 − 2 = 6`... no: `2^(32−27) − 2 = 30` usable.

I drilled this across dozens of addresses and prefixes until reading `/26` as "block size 64" or `/30` as "block size 4, two usable, a point-to-point link" was immediate. That fluency is what lets the rest of the network design move quickly: when I assign a VLAN a `/24` or hand a router interface the last host of a subnet, the arithmetic is already done in my head.
