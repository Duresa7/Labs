# Lab topology

Network and identity layout for the lab. On-prem segments are routed VLANs on the Proxmox cluster; the cloud side is a Microsoft Entra tenant reached over the internet from the sync server.

```mermaid
flowchart TB
    subgraph CLOUD["Microsoft Entra ID (cloud tenant)"]
        ENTRA["Entra ID directory<br/>verified domain: corplab.example.com"]
    end

    subgraph ONPREM["On-prem: corp.local"]
        subgraph SRV["AD servers - 10.10.10.0/24"]
            DC1["CORP-DC01<br/>FSMO + DNS<br/>10.10.10.10"]
            DC2["CORP-DC02<br/>GC + DNS<br/>10.10.10.11"]
            SYNC["Entra Connect<br/>sync server"]
        end
        subgraph WKS["Managed endpoints - 10.10.20.0/24"]
            W1["WS-01<br/>Windows 11 Pro<br/>10.10.20.21"]
            L1["LAPTOP-01<br/>Windows 11 Enterprise<br/>10.10.20.31"]
        end
        subgraph MGMT["Admin / mgmt - 10.10.30.0/24"]
            ADM["Admin workstation<br/>Windows Admin Center<br/>10.10.30.50"]
        end
        subgraph REDTEAM["Isolated test segment"]
            KALI["kali-pen<br/>Kali Linux"]
        end
    end

    DC1 <-->|AD replication| DC2
    DC1 --- SYNC
    SYNC -->|Password Hash Sync| ENTRA
    W1 -->|GPO + hybrid join| DC1
    L1 -->|GPO + hybrid join| DC1
    L1 -.->|SSO token| ENTRA
    ADM -->|WinRM 5985 / SSH 22| DC1
    KALI -.->|attack traffic| SRV
```

| Segment | Range | Hosts |
|---|---|---|
| AD servers | `10.10.10.0/24` | `CORP-DC01` (.10), `CORP-DC02` (.11), Entra Connect sync server |
| Managed endpoints | `10.10.20.0/24` | `WS-01` (.21), `LAPTOP-01` (.31) |
| Admin / management | `10.10.30.0/24` | Admin workstation running Windows Admin Center (.50) |
| Isolated test | separate segment | `kali-pen` |
