# IT Lab

Hands-on IT and systems-administration work, organized by the platform it runs on. The center of it is Linux, the foundation under most of my other infrastructure: the Proxmox hosts, the cloud instances, and the security tooling all sit on top of it, so I built that foundation on purpose rather than picking it up in fragments. Alongside it sits the scripting that automates these systems (Python and PowerShell) and the Windows administration work that keeps the other half of the estate patched and running.

For the network side of my infrastructure see my [Network-Lab](https://github.com/Duresa7/Network-Lab); for cloud work see [Cloud-Lab](https://github.com/Duresa7/Cloud-Lab); for the day-to-day home services see [Homelab-Project](https://github.com/Duresa7/Homelab-Project).

> **A note on the values in here.** User names, host names, file names, and any address tied to me or my network have been replaced with placeholders to protect my privacy. The commands, the order I ran them in, and the behavior I saw are real.

## Projects

| Project | What it covers |
|---|---|
| [01 - Linux command-line fundamentals](projects/01-linux-command-line-fundamentals/README.md) | Navigating the shell, reading the built-in help, and creating, editing, and searching files and directories |
| [02 - Linux system administration](projects/02-linux-system-administration/README.md) | Permissions and ACLs, processes, cron and time sync, package management, storage with LVM, network checks, and SSH |
| [03 - Operating systems compared](projects/03-operating-systems-comparison/README.md) | How Windows, Linux, and macOS differ in kernel architecture, security model, and performance |
| [04 - Scripting for security and automation](projects/04-scripting-and-automation/README.md) | Python utilities (cipher, masking, hashing, IPv4 validation) and PowerShell Windows-automation fundamentals, including two bugs I found and fixed |
| [05 - Windows patch management with PowerShell](projects/05-windows-patch-management/README.md) | Running the full patch cycle from PowerShell with PSWindowsUpdate: surveying updates, controlling reboots, logging to text and CSV, and verifying with Get-HotFix |
