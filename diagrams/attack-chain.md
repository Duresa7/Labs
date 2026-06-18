# Attack chain and the control that stops each step

The Kali pass against `corp.local`, read left to right. Each attack is paired with the hardening from [chapter 02](../docs/02-gpo-security-hardening.md) that blocks or limits it.

```mermaid
flowchart LR
    A["Recon<br/>nmap, enum4linux-ng"] --> B["LLMNR/NBT-NS poisoning<br/>Responder"]
    B --> C["Password spray<br/>kerbrute"]
    C --> D["Kerberoast<br/>GetUserSPNs / Rubeus"]
    D --> E["Graph the domain<br/>BloodHound"]
    E --> F["Dump LSASS<br/>mimikatz"]
    F --> G["Reuse cached creds<br/>offline logon"]

    B -. blocked by .-> B2["LLMNR/NBT-NS disabled"]
    C -. limited by .-> C2["Lockout: 5 tries / 30 min"]
    D -. limited by .-> D2["No weak SPN accounts;<br/>long service passwords"]
    F -. blocked by .-> F2["LSA protection<br/>RunAsPPL"]
    G -. blocked by .-> G2["Cached logons = 0"]
```

The point of the exercise is the dotted lines. An attack chain that reads cleanly on an unhardened domain keeps hitting walls here, and each wall traces back to a specific Group Policy setting I can point to.
