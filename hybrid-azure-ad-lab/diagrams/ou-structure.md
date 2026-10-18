# OU and account structure

The `corp.local` organizational-unit tree. Accidental-deletion protection is enabled on every custom OU. Managed users and managed workstations sit in their own OUs so the restriction GPOs apply by location, not by hand-editing membership.

```mermaid
flowchart TD
    ROOT["corp.local"]

    ROOT --> ADMIN["OU=Admin-Accounts"]
    ADMIN --> DA["OU=Domain-Admins<br/>acarter (Alex Carter)"]
    ADMIN --> SVC["OU=Service-Accounts<br/>(empty)"]

    ROOT --> USERS["OU=Users-Accounts"]
    USERS --> UMAN["OU=Managed<br/>jack-user, test-user-1"]

    ROOT --> WKS["OU=Workstations"]
    WKS --> WMAN["OU=Managed<br/>WS-01, LAPTOP-01, WS-02"]
    WKS --> WSTG["OU=Staging<br/>LAPTOP-STG-01"]

    ROOT --> GRPS["OU=Security-Groups<br/>GRP-ManagedUsers<br/>GRP-ManagedWorkstations"]
```

| Object | Type | Notes |
|---|---|---|
| `acarter` | User | Domain Admin. UPN `acarter.adm@corp.local`. Only member of Domain Admins |
| `jack-user` | User | Managed user. Member of `GRP-ManagedUsers`. Logon-hours enforced |
| `test-user-1` | User | Managed user. Member of `GRP-ManagedUsers` |
| `GRP-ManagedUsers` | Group | Apply target for `GPO-ManagedUsers-Restrictions` |
| `GRP-ManagedWorkstations` | Group | Tracks managed machines |
| `OU=Staging` | OU | Holding spot for a machine while an admin installs approved software, before it returns to Managed |
