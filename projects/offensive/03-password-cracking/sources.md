# Sources

- **hashcat wiki and `--help` (hash modes and attack modes).** `https://hashcat.net/wiki/`
  The `-m` (hash-type) and `-a` (attack-mode) options used in [commands.md](commands.md).
- **hashcat example hashes (identifying the right `-m`).** `https://hashcat.net/wiki/doku.php?id=example_hashes`
  How a hash's format maps to a mode, the "identify the algorithm first" step.
- **OWASP, "Password Storage Cheat Sheet."** `https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html`
  The defensive side: salted, slow KDFs (bcrypt, scrypt, Argon2) and why they defeat the attack.
- **NIST SP 800-63B, "Digital Identity Guidelines: Authentication."** `https://pages.nist.gov/800-63-3/sp800-63b.html`
  Length and memorized-secret guidance behind the "the KDF buys time, the password still has to be worth it" point.
- **Completed local hashcat screenshot.**
  Source for the terminal evidence in `evidence/`. Raw source folder names and source labels are not published.
