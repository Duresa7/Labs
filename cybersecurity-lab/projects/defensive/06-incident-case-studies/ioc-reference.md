# Indicator reference

Publicly reported indicators and techniques for the incidents analyzed in this project, the way I tabulated them while studying each breach. Everything here is open-source threat intelligence drawn from vendor and government advisories (see [sources.md](sources.md)); none of it is private data. Use the cited advisories for the authoritative, complete indicator lists.

## Colonial Pipeline / DarkSide (2021)

| Type | Indicator | Note |
|---|---|---|
| Initial access | Legacy VPN account, no MFA | password found in a prior credential leak |
| C2 IP | `198.54.117.197` | publicly reported DarkSide infrastructure |
| Domain | `baroquetees.com` | publicly reported staging domain |
| Tooling | Cobalt Strike over TOR | post-exploitation framework |
| Malware hash | (representative sample; see CISA AA21-131A) | DarkSide payload family |

**ATT&CK mapping I used:** Valid Accounts (T1078), Command and Control (TA0011), Exfiltration (TA0010), Data Encrypted for Impact (T1486). I rebuilt this in the ATT&CK Navigator and wrote a practice YARA rule keyed on a known DarkSide string.

## MOVEit Transfer / Clop (2023)

| Type | Indicator | Note |
|---|---|---|
| Vulnerability | `CVE-2023-34362` | SQL injection in MOVEit Transfer |
| Web shell | `human2.aspx` (LEMURLOOT) | planted in the MOVEit web root |
| On-disk path | `C:\MOVEitTransfer\wwwroot\human2.aspx` | location of the web shell |
| Trigger | HTTP header `X-siLock-Comment` | custom header that activated the shell |
| C2 IP | `92.118.36.112` | publicly reported Clop infrastructure |

**The detection takeaway:** "a new `.aspx` appears in a web-serving directory" is exactly what a file-integrity rule catches, which connects this case to [the detection-engineering project](../03-detection-engineering/README.md).

## MGM / Caesars (Scattered Spider, 2023)

| Type | Indicator | Note |
|---|---|---|
| Initial access (MGM) | Vishing the help desk -> Okta identity reset | social engineering, no malware on the way in |
| Impact (MGM) | Encryption of 100+ VMware ESXi hosts | reported impact >$100M, no ransom paid |
| Initial access (Caesars) | Third-party IT vendor (supply chain) | reported ~$15M paid |

There are few file/network IOCs for these two because the decisive vector was human, which is the point: identity-verification procedure and vendor-access scoping were the controls that mattered, not a signature.
