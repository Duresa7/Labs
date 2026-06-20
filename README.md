# Linux Lab

The command line is where most of my other work actually happens. The Proxmox hosts, the cloud instances, and the security tooling all sit on top of Linux, so I set out to build that foundation on purpose rather than picking it up in fragments. I worked through the core administration tasks on a Kali Linux VM and wrote down what each command did and why I reached for it.

The work is split into two projects. The first is about living in the shell: finding my way around, reading the manual, and creating, editing, and searching files. The second is about running the system: ownership and permissions, processes, scheduled jobs, package management, network checks, and remote access over SSH.

The SSH and remote-access work here is the groundwork for the hardening I do in my [Network-Lab](https://github.com/Duresa7/Network-Lab), and the same shell skills carry straight into the cloud instances in my [Cloud-Lab](https://github.com/Duresa7/Cloud-Lab).

> **A note on the values in here.** User names, host names, file names, and any address tied to me or my network have been replaced with placeholders to protect my privacy. The commands, the order I ran them in, and the behavior I saw are real.

## Projects

| Project | What it covers |
|---|---|
| [01 - Command-line fundamentals](projects/01-command-line-fundamentals/README.md) | Navigating the shell, reading the built-in help, and creating, editing, and searching files and directories |
| [02 - System administration](projects/02-system-administration/README.md) | Permissions and ownership, processes, cron scheduling and time sync, package management, network checks, and SSH |
