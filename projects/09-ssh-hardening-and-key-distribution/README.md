# SSH hardening and key distribution

SSH is the control plane for the lab. If it accepts weak logins, every firewall rule and VLAN boundary matters less, because management access becomes the easier path. This project records how I moved the fleet toward key-only SSH, no direct root login, and repeatable key distribution from an Ansible controller.

Credential files, public-key blobs, and local environment files are not part of this repository. This writeup keeps the policy, grouping, and workflow.

## Policy

The baseline is small on purpose:

```sshconfig
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
```

I use that as the minimum state for managed Linux hosts. Direct root login is disabled, password login is off, and a host must already know an approved public key before accepting an SSH session.

The version published with this project adds an explicit user boundary:

```sshconfig
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers admin ansible
```

`admin` represents the human admin account. `ansible` represents the automation account where a host needs controller-driven updates. The source fleet had a few transitional targets that still used `root` for automation; I treated those as cleanup targets, not the end state.

## Fleet structure

The SSH client map has aliases for the gateway, Proxmox management, containers, application VMs, a storage host, lab domain controllers, and a security host, grouped by function:

| Group | Example hosts | Addressing | Target account |
|---|---|---|---|
| Management | `proxmox-node-01`, `gateway` | `192.168.70.x`, `192.168.1.x` | `admin` |
| Container services | `docker-host-01`, `storage-host-01`, `edge-host-01` | `192.168.40.x`, `192.168.90.x` | `admin` |
| Application VMs | `app-01`, `db-01`, `web-01` | `192.168.80.x` | `admin` |
| Security tooling | `security-01` | `192.168.70.x` | `admin` |
| Automation | `ansible-01` | `192.168.40.x` | `ansible` |

That grouping matters because SSH policy is not only a daemon setting. It is also an inventory problem: I need to know which account should exist on each host, which hosts are still transitional, and which network segment the controller must reach.

## Ansible distribution pattern

An Ansible playbook pushes the same two approved public keys to each target:

```yaml
---
- hosts: linux_fleet
  become: true
  vars:
    ssh_admin_users:
      - admin
      - ansible
    approved_public_keys:
      - "{{ lookup('file', 'files/admin-workstation.pub') }}"
      - "{{ lookup('file', 'files/backup-admin.pub') }}"

  tasks:
    - name: Ensure admin accounts exist
      ansible.builtin.user:
        name: "{{ item }}"
        groups: sudo
        append: true
        shell: /bin/bash
        state: present
      loop: "{{ ssh_admin_users }}"

    - name: Install approved public keys
      ansible.posix.authorized_key:
        user: "{{ item.0 }}"
        key: "{{ item.1 }}"
        state: present
        exclusive: false
      loop: "{{ ssh_admin_users | product(approved_public_keys) | list }}"
```

The key point is idempotence. I can rerun the playbook after adding a host, replacing a laptop, or rotating a key, and the fleet converges without hand-editing `authorized_keys` on each machine.

## Rollout order

I used this order so I would not lock myself out:

1. Add or confirm the admin account on each target.
2. Install approved public keys with Ansible.
3. Test SSH from the admin workstation and from the Ansible controller.
4. Apply the hardened `sshd` policy.
5. Restart SSH on one host at a time.
6. Keep an existing session open until a new key-based session succeeds.

That last step is boring and useful. A live session is the rollback path if a file permission, user, or `sshd_config` line is wrong.

## Validation

For each target I checked:

- `sshd -t` returns cleanly before restart;
- password login is refused;
- direct root login is refused;
- `admin` can connect with an approved key;
- Ansible can run a no-change ping or facts task;
- host firewall policy still limits SSH to the management path.

The result is a management plane that matches the rest of the network design: narrow reachability, key-based identity, and repeatable configuration instead of one-off host edits.
