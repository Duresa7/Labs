# Sources

- **Wireshark User's Guide, "Following Protocol Streams."** `https://www.wireshark.org/docs/wsug_html_chunked/ChAdvFollowStreamSection.html`
  The Follow TCP Stream feature used to reassemble the Telnet and SSH sessions into the captures in `evidence/`.
- **RFC 854, "Telnet Protocol Specification."** `https://www.rfc-editor.org/rfc/rfc854`
  Confirms Telnet carries data, including credentials, with no encryption, which is why the stream is readable.
- **RFC 4253, "The Secure Shell (SSH) Transport Layer Protocol."** `https://www.rfc-editor.org/rfc/rfc4253`
  The encryption that makes the SSH stream unreadable after the handshake.
- **Metasploitable 2 documentation (Rapid7).** `https://docs.rapid7.com/metasploit/metasploitable-2/`
  The intentionally vulnerable target; its default `msfadmin` credentials are public and were the ones captured in the Telnet stream.
- **NIST SP 800-52 Rev. 2, guidance on using TLS / avoiding cleartext protocols.** `https://csrc.nist.gov/pubs/sp/800/52/r2/final`
  Background for the recommendation to replace plaintext protocols with encrypted equivalents.
