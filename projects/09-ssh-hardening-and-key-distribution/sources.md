# Sources

- **Completed local SSH daemon baseline.**
  Source for the key-only, no-root, no-password policy. The public file is [sshd-key-only.conf](sshd-key-only.conf).
- **Completed local SSH client alias map.**
  Used only for fleet structure: management, containers, application VMs, storage, automation, and security tooling. Raw aliases, users, and addresses are not published.
- **Completed local Ansible key-distribution report.**
  Source for the grouped inventory and public-key distribution workflow. Public-key blobs, private-key paths, and local usernames were not copied.
- **OpenSSH `sshd_config` manual.** `https://man.openbsd.org/sshd_config`
  Reference for `PermitRootLogin`, `PubkeyAuthentication`, `PasswordAuthentication`, `KbdInteractiveAuthentication`, and `AllowUsers`.
- **Ansible `authorized_key` module documentation.** `https://docs.ansible.com/ansible/latest/collections/ansible/posix/authorized_key_module.html`
  Reference for idempotently managing public keys in `authorized_keys`.
