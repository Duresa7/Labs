# Operating systems compared: Windows, Linux, and macOS

Most of my work runs across all three desktop operating systems, so I wrote up how they actually differ under the hood, focused on the parts that matter for administration and security: the kernel architecture, the security model, and where each one fits. This is an analysis, not a lab.

## Kernel architecture

The kernel design shapes everything above it.

| OS | Kernel | What that means in practice |
|---|---|---|
| Windows | Hybrid (NT) | Combines microkernel and monolithic ideas; very broad hardware support, with kernel-mode drivers forming a large part of the attack surface |
| Linux | Monolithic | Drivers, filesystems, and core services run together in kernel space; open source, so it can be modified and tuned for a role (server, embedded) |
| macOS | Hybrid (XNU) | A Mach microkernel core with a BSD layer; Unix underpinnings on a small set of tightly controlled Apple hardware |

The practical split: Linux trades some process isolation for speed and is reshaped per workload; Windows prioritizes compatibility across an enormous hardware range; macOS narrows the hardware to a few known configurations and builds stability on a Unix base.

## Security model

- **Windows** centers on the user and group model, UAC for privilege elevation, BitLocker for disk encryption, and Defender built in. Its market dominance makes it the largest malware target, so patch cadence matters most here.
- **Linux** leans on strict file permissions and ownership, an optional mandatory-access-control layer (SELinux or AppArmor), and a small default attack surface because a server install runs almost nothing it does not need. The security depends heavily on how it is configured.
- **macOS** combines Unix permissions with Apple's own controls: Gatekeeper (only signed and notarized apps run by default), System Integrity Protection (the OS protects its own files even from root), and FileVault for encryption.

The pattern: Windows defends a huge general-purpose surface, Linux hands you the tools and expects you to configure them, and macOS locks the platform down by default and limits what the user can change.

## Performance and fit

Linux is the lightest and most tunable, which is why it runs most servers and embedded systems. Windows carries the most overhead but the widest software and gaming support. macOS is optimized for its own hardware, which keeps it steady in creative and professional use but not flexible across arbitrary machines.

## Where each one lands

- **Windows**: general desktops, enterprise applications, gaming, anywhere broad compatibility wins.
- **Linux**: servers, development, security tooling, anywhere control and a small footprint win.
- **macOS**: creative and professional workstations on Apple hardware, anywhere a locked-down Unix desktop wins.

Knowing these trade-offs is what lets me pick the right OS for a role and reason about how to secure each one, instead of treating "the computer" as a single thing.

## Files in this project

- [sources.md](sources.md) - references for the architecture, security, and performance details.
