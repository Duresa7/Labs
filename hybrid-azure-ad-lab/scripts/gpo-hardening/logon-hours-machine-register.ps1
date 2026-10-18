<#
.SYNOPSIS
  Registers scheduled tasks that enforce logon-hours for a managed user.
.DESCRIPTION
  Copies the logon-hours action script into ProgramData, creates a dedicated Task
  Scheduler folder, and registers a recurring enforcement task plus timed warning
  and logoff tasks for weekday and weekend windows. All tasks run as SYSTEM with
  highest privileges and invoke the action script with the matching mode.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Credentials are prompted at runtime, never hardcoded.
#>
$ErrorActionPreference = 'SilentlyContinue'
$programData = 'C:\ProgramData\CORP\LogonHours'
New-Item -ItemType Directory -Path $programData -Force | Out-Null
$source = Join-Path $PSScriptRoot 'logon-hours-machine-action.ps1'
$action = Join-Path $programData 'logon-hours-machine-action.ps1'
Copy-Item -LiteralPath $source -Destination $action -Force
try {
  $svc = New-Object -ComObject Schedule.Service
  $svc.Connect()
  $root = $svc.GetFolder('\')
  try { $null = $root.GetFolder('CORP') } catch { $null = $root.CreateFolder('CORP') }
} catch {}
function Register-CorpTask {
  param([string]$Name,[string]$Schedule,[string]$Days,[string]$Time,[string]$Mode)
  $taskName = '\CORP\' + $Name
  $tr = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$action`" $Mode"
  if ($Schedule -eq 'MINUTE') {
    & schtasks.exe /Create /F /TN $taskName /SC MINUTE /MO 5 /RU SYSTEM /RL HIGHEST /TR $tr | Out-Null
  } else {
    & schtasks.exe /Create /F /TN $taskName /SC WEEKLY /D $Days /ST $Time /RU SYSTEM /RL HIGHEST /TR $tr | Out-Null
  }
}
Register-CorpTask 'Jack Logon Hours Enforce Every 5 Minutes' 'MINUTE' '' '' 'enforce'
Register-CorpTask 'Jack Logon Hours Warning 30 Mon-Thu' 'WEEKLY' 'MON,TUE,WED,THU' '20:30' 'warn30_2100'
Register-CorpTask 'Jack Logon Hours Warning 10 Mon-Thu' 'WEEKLY' 'MON,TUE,WED,THU' '20:50' 'warn10_2100'
Register-CorpTask 'Jack Logon Hours Warning 5 Mon-Thu' 'WEEKLY' 'MON,TUE,WED,THU' '20:55' 'warn5_2100'
Register-CorpTask 'Jack Logon Hours Logoff Mon-Thu' 'WEEKLY' 'MON,TUE,WED,THU' '21:00' 'logoff_2100'
Register-CorpTask 'Jack Logon Hours Warning 30 Fri-Sun' 'WEEKLY' 'FRI,SAT,SUN' '21:30' 'warn30_2200'
Register-CorpTask 'Jack Logon Hours Warning 10 Fri-Sun' 'WEEKLY' 'FRI,SAT,SUN' '21:50' 'warn10_2200'
Register-CorpTask 'Jack Logon Hours Warning 5 Fri-Sun' 'WEEKLY' 'FRI,SAT,SUN' '21:55' 'warn5_2200'
Register-CorpTask 'Jack Logon Hours Logoff Fri-Sun' 'WEEKLY' 'FRI,SAT,SUN' '22:00' 'logoff_2200'
