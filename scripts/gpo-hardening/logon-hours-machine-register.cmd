REM SYNOPSIS: Launches the logon-hours scheduled-task registration script.
REM DESCRIPTION: Wrapper that runs logon-hours-machine-register.ps1 from the same
REM   folder with an unrestricted execution policy to register the enforcement tasks.
REM NOTES: Lab: corp.local (Windows Server 2025 Active Directory lab)
REM   Identifiers (domain, hosts, users, IPs) are sanitized placeholders.
REM   Credentials are prompted at runtime, never hardcoded.
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0logon-hours-machine-register.ps1"
exit /b 0
