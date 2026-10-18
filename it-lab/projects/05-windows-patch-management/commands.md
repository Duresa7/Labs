# Commands

Every command from this project, grouped by stage. Run them from an elevated ("Run as administrator") Windows PowerShell session. File paths use `$HOME` in place of a real profile path.

## Set up the update module

```powershell
Install-Module PSWindowsUpdate -Force        # install the community module from the PowerShell Gallery
Set-ExecutionPolicy RemoteSigned -Scope Process   # allow the signed module to load, for this session only
Import-Module PSWindowsUpdate                 # load the update cmdlets
```

## Survey what is pending

```powershell
Get-WindowsUpdate                             # list all available updates: KB, size, title
Get-WindowsUpdate | Where-Object {$_.Title -like "*Security*"}   # narrow to security updates
```

## Apply updates with reboot control

```powershell
Get-WindowsUpdate -AcceptAll -Install         # download and install everything pending
Install-WindowsUpdate -AcceptAll -IgnoreReboot   # install but suppress the automatic restart
Get-WindowsUpdate -KBArticleID "KB5054979" -Install -AcceptAll -IgnoreReboot   # install one specific update
```

## Log the results

```powershell
Get-WindowsUpdate | Out-File "$HOME\Documents\available-updates.txt"
Get-WindowsUpdate | Export-Csv "$HOME\Documents\available-updates.csv" -NoTypeInformation
Get-WindowsUpdate -AcceptAll -Install | Tee-Object -FilePath "$HOME\Documents\install-log.txt"
Get-WindowsUpdate -AcceptAll -Install | Export-Csv "$HOME\Documents\install-log.csv" -NoTypeInformation
```

## Verify and reboot

```powershell
Get-HotFix                                    # read back the updates the system recorded as installed
Restart-Computer                              # take the reboot manually, after verifying
```
