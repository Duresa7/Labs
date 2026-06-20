# Sources

- **Nmap reference guide, "Port Scanning Techniques."** `https://nmap.org/book/man-port-scanning-techniques.html`
  The behavior of `-sT`, `-sS`, `-sF`, `-sN`, `-sX`, and `-O` and how each infers open versus closed.
- **Nmap reference guide, "OS Detection."** `https://nmap.org/book/osdetect.html`
  How the `-O` fingerprint infers the operating system from stack behavior.
- **RFC 793, "Transmission Control Protocol."** `https://www.rfc-editor.org/rfc/rfc793`
  The TCP semantics (a closed port answers an unexpected segment with RST; an open port may stay silent) that the FIN/NULL/Xmas scans exploit.
- **Wireshark User's Guide, display filters.** `https://www.wireshark.org/docs/wsug_html_chunked/ChWorkDisplayFilterSection.html`
  The `ip.addr==... && ip.addr==...` filter used to isolate each exchange.
- **Metasploitable 2 (Rapid7).** `https://docs.rapid7.com/metasploit/metasploitable-2/`
  The intentionally vulnerable target whose open-service profile the fingerprint scan returned.
- **Completed local TCP scan screenshot set.**
  Source for the terminal and Wireshark evidence in `evidence/`. Raw source folder names and source labels are not published.
- **The defensive side:** I tie each scan to the control that stops it; the firewall default-deny posture is the same one I run in my [Network Lab](https://github.com/Duresa7/Network-Lab).
