# Sources

- **Cisco IOS configuration fundamentals and the basic device-security steps.** `https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/fundamentals/configuration/guide/cf_book.html`
  Hostname, `enable secret`, `service password-encryption`, line passwords, and `banner motd`.
- **Cisco, "Configuring Secure Shell (SSH)."** `https://www.cisco.com/c/en/us/support/docs/security-vpn/secure-shell-ssh/4145-ssh.html`
  `crypto key generate rsa`, `ip ssh version 2`, and `transport input ssh` (no Telnet), the basis of the baseline in [../../configs/switch-baseline.cfg](../../configs/switch-baseline.cfg).
- **Cisco Networking Academy, "Introduction to Networks" (CCNA ITN) switch/router build conventions.** `https://www.netacad.com/`
  The build-and-verify methodology (address, secure, `show ip interface brief`, end-to-end ping).
- **Completed local Packet Tracer switch/router, SSH-hardening, and MAC-table exercises.**
  Used as private source evidence for the topology, addressing derivation, SSH controls, ping verification, and MAC-table checks. The `.pka` and `.pkt` binaries are not committed.
