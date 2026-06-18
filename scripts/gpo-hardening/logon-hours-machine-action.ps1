<#
.SYNOPSIS
  Enforces logon-hours for a managed user by warning and logging off sessions.
.DESCRIPTION
  Machine action invoked by scheduled tasks. Finds interactive sessions for the
  managed user via quser, sends timed warning messages ahead of cut-off, and logs
  the user off when the allowed logon window has ended. The allowed window varies
  by day of week. Designed to run as SYSTEM on managed workstations.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
  Credentials are prompted at runtime, never hardcoded.
#>
param([string]$Mode = 'enforce')
function Get-JackSessionIds {
  $lines = & quser.exe 2>$null
  if (-not $lines) { return @() }
  $ids = @()
  foreach ($line in ($lines | Select-Object -Skip 1)) {
    $clean = $line.TrimStart('>', ' ')
    if ($clean -match '^(?:CORP\\)?jack-user\s+') {
      $parts = $clean -split '\s+'
      $id = $parts | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1
      if ($id) { $ids += [int]$id }
    }
  }
  return $ids
}
function Is-JackAllowedNow {
  $now = Get-Date
  switch ($now.DayOfWeek.ToString()) {
    'Sunday'    { $start = 6;  $end = 22 }
    'Monday'    { $start = 15; $end = 21 }
    'Tuesday'   { $start = 15; $end = 21 }
    'Wednesday' { $start = 15; $end = 21 }
    'Thursday'  { $start = 15; $end = 21 }
    'Friday'    { $start = 15; $end = 22 }
    'Saturday'  { $start = 6;  $end = 22 }
    default     { return $false }
  }
  return (($now.Hour -ge $start) -and ($now.Hour -lt $end))
}
function Send-JackMessage([string]$Text) {
  foreach ($id in Get-JackSessionIds) { & msg.exe $id /TIME:300 $Text 2>$null }
}
function Logoff-Jack([string]$Reason) {
  foreach ($id in Get-JackSessionIds) {
    & msg.exe $id /TIME:60 $Reason 2>$null
    Start-Sleep -Seconds 2
    & logoff.exe $id /V 2>$null
  }
}
switch ($Mode) {
  'warn30_2100' { Send-JackMessage 'CORP logon hours: you will be logged off in 30 minutes at 9:00 PM. Save your work now.'; exit 0 }
  'warn10_2100' { Send-JackMessage 'CORP logon hours: you will be logged off in 10 minutes at 9:00 PM. Save your work now.'; exit 0 }
  'warn5_2100'  { Send-JackMessage 'CORP logon hours: you will be logged off in 5 minutes at 9:00 PM. Save your work now.'; exit 0 }
  'logoff_2100' { Logoff-Jack 'CORP logon hours ended at 9:00 PM. This session is being logged off.'; exit 0 }
  'warn30_2200' { Send-JackMessage 'CORP logon hours: you will be logged off in 30 minutes at 10:00 PM. Save your work now.'; exit 0 }
  'warn10_2200' { Send-JackMessage 'CORP logon hours: you will be logged off in 10 minutes at 10:00 PM. Save your work now.'; exit 0 }
  'warn5_2200'  { Send-JackMessage 'CORP logon hours: you will be logged off in 5 minutes at 10:00 PM. Save your work now.'; exit 0 }
  'logoff_2200' { Logoff-Jack 'CORP logon hours ended at 10:00 PM. This session is being logged off.'; exit 0 }
  default { if (-not (Is-JackAllowedNow)) { Logoff-Jack 'CORP logon hours are not active right now. This session is being logged off.' }; exit 0 }
}
