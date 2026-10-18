<#
.SYNOPSIS
  Trigger an Entra Connect sync cycle and report sync health.
.DESCRIPTION
  Forces a sync rather than waiting for the default 30-minute scheduler, then
  reports the scheduler state and the most recent connector run results.
.NOTES
  Lab: corp.local  (Windows Server 2025 Active Directory lab)
  Run on the Entra Connect sync server.
#>

Import-Module ADSync

# Scheduler should be enabled with a 30-minute interval
Get-ADSyncScheduler | Select-Object SyncCycleEnabled, CurrentlyEffectiveSyncCycleInterval, NextSyncCyclePolicyType

# Initial = full import/sync (first run). Use Delta for routine runs.
Start-ADSyncSyncCycle -PolicyType Initial

# After the cycle finishes, review the latest run per connector
Get-ADSyncConnectorRunStatus
Get-ADSyncConnector | ForEach-Object {
    $name = $_.Name
    $run  = Get-ADSyncRunProfileResult -ConnectorName $name -NumberRequested 1
    [pscustomobject]@{ Connector = $name; Result = $run.Result; End = $run.EndDate }
}
