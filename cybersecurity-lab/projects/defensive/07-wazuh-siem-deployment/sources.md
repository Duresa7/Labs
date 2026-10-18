# Sources

## Wazuh deployment

- **Wazuh documentation, "Quickstart."** `https://documentation.wazuh.com/current/quickstart.html`
  The assisted all-in-one installation path used for the single-node build.
- **Wazuh documentation, "Deploying Wazuh agents on Linux endpoints."** `https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-linux.html`
  The Linux agent package workflow and `WAZUH_MANAGER` enrollment variable.
- **Wazuh documentation, "Agent enrollment requirements."** `https://documentation.wazuh.com/current/user-manual/agent/agent-enrollment/requirements.html`
  The required Wazuh agent communication and enrollment ports, TCP 1514 and TCP 1515.

## Wazuh capabilities

- **Wazuh documentation, "File integrity monitoring."** `https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/index.html`
  The FIM capability used to watch for file additions, changes, and deletions.
- **Wazuh documentation, "Security Configuration Assessment."** `https://documentation.wazuh.com/current/user-manual/capabilities/sec-config-assessment/index.html`
  The SCA capability used to surface endpoint configuration findings.
- **Wazuh documentation, "Vulnerability detection."** `https://documentation.wazuh.com/current/user-manual/capabilities/vulnerability-detection/index.html`
  The vulnerability module that correlates software inventory with CVE intelligence.

## Related portfolio context

- **Network-Lab, "Zone-based firewall."** `https://github.com/Duresa7/Network-Lab/blob/main/projects/02-zone-based-firewall/README.md`
  The firewall project that documents the SIEM agent-port rules between zones.
- **Homelab-Project, "Self-hosted services."** `https://github.com/Duresa7/Homelab-Project/blob/main/docs/06-self-hosted-services.md`
  The public homelab context for the WordPress service monitored by Wazuh.
