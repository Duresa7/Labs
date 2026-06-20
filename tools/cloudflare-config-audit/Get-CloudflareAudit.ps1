param(
  [string]$AccountId = $env:CLOUDFLARE_ACCOUNT_ID,
  [string[]]$ZoneNames = @("example.com", "example.net", "example.org"),
  [string]$TunnelId = $env:CLOUDFLARE_TUNNEL_ID,
  [string]$OutputPath = "tools/cloudflare-audit-live.json"
)

$ErrorActionPreference = "Stop"

$token = $env:CLOUDFLARE_API_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
  throw "CLOUDFLARE_API_TOKEN is not set."
}

$headers = @{
  Authorization = "Bearer $token"
  "Content-Type" = "application/json"
}

function Invoke-CfGet {
  param([string]$Path)
  $uri = "https://api.cloudflare.com/client/v4$Path"
  $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
  if (-not $response.success) {
    $messages = @($response.errors | ForEach-Object { $_.message }) -join "; "
    throw "Cloudflare API request failed for $Path`: $messages"
  }
  return $response.result
}

$out = [ordered]@{
  collectedAt = (Get-Date).ToString("o")
  tokenVerify = $null
  accounts = @()
  selectedAccountId = $AccountId
  zones = @()
  tunnels = @()
  tunnelConfiguration = $null
  tunnelConnections = $null
  accessApplications = $null
  notes = @()
}

$out.tokenVerify = Invoke-CfGet "/user/tokens/verify"

try {
  $out.accounts = @(Invoke-CfGet "/accounts")
  if ([string]::IsNullOrWhiteSpace($AccountId) -and $out.accounts.Count -eq 1) {
    $AccountId = $out.accounts[0].id
    $out.selectedAccountId = $AccountId
  }
} catch {
  $out.notes += "Could not list accounts: $($_.Exception.Message)"
}

foreach ($zoneName in $ZoneNames) {
  try {
    $zones = @(Invoke-CfGet "/zones?name=$([uri]::EscapeDataString($zoneName))")
    foreach ($zone in $zones) {
      $records = @(Invoke-CfGet "/zones/$($zone.id)/dns_records?per_page=500")
      $out.zones += [ordered]@{
        name = $zone.name
        id = $zone.id
        status = $zone.status
        account = $zone.account.name
        nameServers = @($zone.name_servers)
        dnsRecords = @($records | ForEach-Object {
          [ordered]@{
            type = $_.type
            name = $_.name
            content = if ($_.type -in @("TXT")) { "<redacted-or-long-text>" } else { $_.content }
            proxied = $_.proxied
            ttl = $_.ttl
            priority = $_.priority
            comment = $_.comment
            tags = @($_.tags)
          }
        })
      }
    }
  } catch {
    $out.notes += "Could not collect zone $zoneName`: $($_.Exception.Message)"
  }
}

if (-not [string]::IsNullOrWhiteSpace($AccountId)) {
  try {
    $out.tunnels = @(Invoke-CfGet "/accounts/$AccountId/cfd_tunnel?per_page=500")
  } catch {
    $out.notes += "Could not list cfd_tunnel endpoint: $($_.Exception.Message)"
    try {
      $out.tunnels = @(Invoke-CfGet "/accounts/$AccountId/tunnels?per_page=500")
    } catch {
      $out.notes += "Could not list tunnels endpoint: $($_.Exception.Message)"
    }
  }

  if ([string]::IsNullOrWhiteSpace($TunnelId) -and $out.tunnels.Count -eq 1) {
    $TunnelId = $out.tunnels[0].id
  }

  if (-not [string]::IsNullOrWhiteSpace($TunnelId)) {
    try {
      $out.tunnelConfiguration = Invoke-CfGet "/accounts/$AccountId/cfd_tunnel/$TunnelId/configurations"
    } catch {
      $out.notes += "Could not get tunnel configuration for $TunnelId`: $($_.Exception.Message)"
    }
    try {
      $out.tunnelConnections = @(Invoke-CfGet "/accounts/$AccountId/cfd_tunnel/$TunnelId/connections")
    } catch {
      $out.notes += "Could not get tunnel connections for $TunnelId`: $($_.Exception.Message)"
    }
  }

  try {
    $out.accessApplications = @(Invoke-CfGet "/accounts/$AccountId/access/apps?per_page=500")
  } catch {
    $out.notes += "Could not collect Access applications: $($_.Exception.Message)"
  }
} else {
  $out.notes += "No account ID supplied or discovered; tunnel and Access collection skipped."
}

$dir = Split-Path -Parent $OutputPath
if ($dir) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$out | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Output "Wrote $OutputPath"
