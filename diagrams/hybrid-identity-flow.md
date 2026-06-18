# Hybrid identity flow

How an on-prem `corp.local` account becomes a usable cloud identity, and how a domain-joined laptop signs in to cloud apps without a second password prompt.

```mermaid
sequenceDiagram
    participant AD as On-prem AD (corp.local)
    participant SYNC as Entra Connect (PHS)
    participant ENTRA as Microsoft Entra ID
    participant USER as LAPTOP-01 (jack-user)

    Note over AD,SYNC: Directory synchronization
    AD->>SYNC: Source objects (users, groups)
    SYNC->>SYNC: Hash the password hash again (PHS)
    SYNC->>ENTRA: Sync object + password hash (delta every 30 min)
    ENTRA-->>SYNC: Confirms object as "Synced from on-prem"

    Note over USER,ENTRA: Sign-in with Seamless SSO
    USER->>AD: Kerberos TGT at domain logon
    USER->>ENTRA: Reach a cloud app
    ENTRA->>USER: 401, asks for a Kerberos ticket for AZUREADSSOACC
    USER->>AD: Request service ticket for AZUREADSSOACC
    AD-->>USER: Kerberos service ticket
    USER->>ENTRA: Present ticket
    ENTRA-->>USER: Issues token, no password prompt
```

Two things make this work without paid licensing:

- **Password Hash Sync** copies a re-hashed version of the on-prem password hash into Entra, so the same password works in both places. No federation servers to run.
- **Seamless SSO** installs a computer account (`AZUREADSSOACC`) in AD. Domain-joined, on-network machines get a silent token using their existing Kerberos ticket.

Hybrid Azure AD join is published through the Service Connection Point (SCP) that Entra Connect writes into the on-prem configuration partition, so domain-joined devices register themselves into Entra automatically.
