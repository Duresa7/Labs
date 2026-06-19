# WireGuard command reference

The CLI workflow behind the Management Access server. UniFi generates the server side through its UI, but these are the underlying `wg` / `wg-quick` commands that do the same thing and that I use to reason about and verify the tunnel. Keys and addresses are placeholders; the full server config shape is in [../../configs/wireguard-server.example.conf](../../configs/wireguard-server.example.conf).

## Key generation

```bash
# Server keypair
wg genkey | tee server.key | wg pubkey > server.pub

# A client keypair
wg genkey | tee client.key | wg pubkey > client.pub
```

## Server interface (the gateway side)

```ini
# /etc/wireguard/wg0.conf  -- Management Access server
[Interface]
Address    = 10.200.6.1/24
ListenPort = 51822
PrivateKey = <server-private-key>

[Peer]                       # admin client
PublicKey  = <client-public-key>
AllowedIPs = 10.200.6.2/32   # pinned to a single /32, not the whole range
```

```bash
wg-quick up wg0      # bring the tunnel up
wg show              # verify the peer, handshake time, and transfer counters
wg-quick down wg0    # tear it down
```

## What I check after a connect

```bash
wg show wg0 latest-handshakes   # a recent handshake means the tunnel is live
ping 10.70.0.1                  # reach the management gateway over the tunnel
```

The point is the routing, not the crypto: a connected client lands in `10.200.6.0/24`, which gateway policy ([../02-zone-based-firewall/README.md](../02-zone-based-firewall/README.md)) allows only into the management and server zones. The firewall, not the tunnel, decides what the client can reach.
