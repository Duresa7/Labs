# Cloudflare configuration audit

This tool collects a point-in-time JSON inventory of the Cloudflare pieces that sit outside the home gateway: token status, accounts, selected zones, DNS records, Cloudflare Tunnel inventory, tunnel configuration, tunnel connections, and Access applications.

I wrote it because Cloudflare state can drift away from the local network diagrams. A tunnel can stay online after a service moves, a DNS record can point at an old hostname, or an Access app can keep protecting a route I no longer use. Pulling the account view into one JSON file gives me something to compare before I change firewall, DNS, or remote-access policy.

## Inputs

The script reads secrets and selectors from environment variables:

| Variable | Purpose |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Required API token. The token is never stored in the script. |
| `CLOUDFLARE_ACCOUNT_ID` | Optional account selector. If the token can see only one account, the script discovers it. |
| `CLOUDFLARE_TUNNEL_ID` | Optional tunnel selector for configuration and connection detail. |

The default `$ZoneNames` list uses documentation domains: `example.com`, `example.net`, and `example.org`. Replace them locally when running the audit; do not commit private domain names.

## Output

By default the script writes `tools/cloudflare-audit-live.json`, which is ignored by git. TXT record content is replaced with `<redacted-or-long-text>` because TXT records often carry verification strings or mail-policy details that add little value to a public writeup.

Run from the repository root:

```powershell
$env:CLOUDFLARE_API_TOKEN = "<token>"
$env:CLOUDFLARE_ACCOUNT_ID = "<account-id>"
.\tools\cloudflare-config-audit\Get-CloudflareAudit.ps1
```

Before sharing any output, review the JSON for domain names, account IDs, tunnel IDs, service hostnames, comments, and Access app names.
