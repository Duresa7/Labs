# Sources

All open-source: government and vendor advisories, plus the frameworks I mapped each incident to.

## Colonial Pipeline / DarkSide

- **CISA & FBI, Joint Advisory AA21-131A, "DarkSide Ransomware."** `https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-131a`
- **U.S. Department of Energy, "Colonial Pipeline Cyber Incident."** `https://www.energy.gov/ceser/colonial-pipeline-cyber-incident`
- **FBI, "FBI Statement on Compromise of Colonial Pipeline Networks."** `https://www.fbi.gov/news/press-releases/fbi-statement-on-compromise-of-colonial-pipeline-networks`
- **U.S. Department of Justice, "Department of Justice Seizes $2.3 Million in Cryptocurrency Paid to the Ransomware Extortionists Darkside."** `https://www.justice.gov/archives/opa/pr/department-justice-seizes-23-million-cryptocurrency-paid-ransomware-extortionists-darkside`
- **William Turton and Kartikay Mehrotra, Bloomberg, "Hackers Breached Colonial Pipeline Using Compromised Password."** `https://www.bloomberg.com/news/articles/2021-06-04/hackers-breached-colonial-pipeline-using-compromised-password`
- **TSA, "Pipeline Cybersecurity: Protecting Critical Infrastructure."** `https://www.tsa.gov/news/press/testimony/2021/07/27/pipeline-cybersecurity-protecting-critical-infrastructure`

## MOVEit Transfer / Clop

- **CISA & FBI, Advisory AA23-158A, "#StopRansomware: CL0P Ransomware Gang Exploits CVE-2023-34362 MOVEit Vulnerability."** `https://www.cisa.gov/news-events/cybersecurity-advisories/aa23-158a`
- **NVD, CVE-2023-34362.** `https://nvd.nist.gov/vuln/detail/CVE-2023-34362`
- **Progress Software, MOVEit Transfer security advisory.** `https://www.progress.com/security/moveit-transfer-and-moveit-cloud-vulnerability`

## MGM / Caesars / Scattered Spider

- **CISA & FBI, Advisory AA23-320A, "Scattered Spider."** `https://www.cisa.gov/news-events/cybersecurity-advisories/aa23-320a`
- **Caesars Entertainment, Form 8-K (SEC filing), September 2023.** `https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=caesars`

## Frameworks and tools used in the analysis

- **MITRE ATT&CK** and the **ATT&CK Navigator.** `https://attack.mitre.org/` / `https://mitre-attack.github.io/attack-navigator/`
- **NIST SP 800-61, "Computer Security Incident Handling Guide."** `https://csrc.nist.gov/pubs/sp/800/61/r2/final`
- **YARA** (used to write a practice signature for the DarkSide case). `https://virustotal.github.io/yara/`
- **Sysinternals Process Explorer** (used to reason about how the loaders would present on a host). `https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer`
