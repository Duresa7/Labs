# Mobile forensics and threat analysis

Phones are where a lot of real compromise happens now, and they are harder to reason about than a laptop: the data sits in app-specific databases, much of it encrypted, and a lot of it is built to disappear. This project covers both sides of that. First, how a real mobile attack works, mapped to MITRE ATT&CK. Then, how you forensically investigate a messaging app afterward, using Snapchat on iOS as the worked example because an ephemeral-by-design app is the hardest case.

These are analyses I wrote, not a live acquisition. The forensic methodology, the database structures, and the ATT&CK mappings are drawn from the tools and published research cited in [sources.md](sources.md).

## The threat: QR-code phishing on mobile (Star Blizzard)

Star Blizzard ran a campaign whose goal was to take over victims' WhatsApp accounts by getting them to scan a QR code. No password needed: the QR code linked the attacker's device as a companion session and handed them the account. Mapped to MITRE ATT&CK for Mobile, two techniques carry it:

- **Credential Access ([TA0031](https://attack.mitre.org/tactics/TA0031/)).** The whole point of the QR trick is to get access without the password, by capturing the session itself rather than the credential.
- **Adversary-in-the-Middle ([T1638](https://attack.mitre.org/techniques/T1638/)).** Linking a companion session puts the attacker between the user and WhatsApp, positioned to read the traffic.

This is not a niche trick. Lookout's 2022 mobile phishing report found mobile phishing rose more than 50% between 2021 and 2022, because the small screen hides the cues (the full URL, the sender details) that give a phish away on a desktop. The defender's takeaway: QR and session-linking flows deserve the same suspicion as a login page, and account-takeover detection has to watch for a new linked device, not only a new password.

## The forensics: investigating Snapchat on iOS

When a mobile account or device is part of an investigation, the evidence lives inside the app's own storage. Snapchat is the hard case because it is built to be ephemeral and it encrypts saved media, so it shows what good mobile app forensics has to handle. I worked through four questions; the full methodology is in [snapchat-ios-artifact-analysis.md](snapchat-ios-artifact-analysis.md).

- **Are the timestamps trustworthy?** `scdb-27.sqlite3` stores both a capture time and a created time in `ZGALLERYENTRY` / `ZGALLERYSNAP`, in Unix epoch milliseconds (divide by 1000 before converting). They reconstruct a reliable timeline as long as the device clock was right, which is why you cross-check them against iOS system logs or photo EXIF.
- **Is the recovered media intact and really theirs?** Decrypt the gallery media with the keys in `gallery.encrypteddb` (a clean AES decryption is itself an integrity signal), hash each file at acquisition and after extraction, and tie the file back to the database by its `EXTERNAL_KEY` through `cache_controller.db` into `scdb-27.sqlite3`.
- **Will it hold up in court?** Chain of custody from seizure on: isolate the phone (airplane mode or a Faraday bag) so nothing syncs or remote-wipes, image with a trusted full-file-system method, hash the image, work only on copies, log every transfer, and stay inside the warrant's scope.
- **How do you keep up?** Snapchat changes its schema and file locations often, so the methodology has to be maintained against current DFIR research rather than trusted from an old writeup.

## How the two sides connect

The threat is why you open the investigation; the forensics is how you reconstruct what happened. A QR-phishing account takeover leaves traces, a new linked session and activity at odd hours, and the same timestamp and integrity discipline used on Snapchat artifacts is what lets you prove when an account was accessed and from where. Mobile is its own discipline, but the loop is the same as the rest of this lab: understand the attack, then build the analysis that catches and proves it.

## Files in this project

- [snapchat-ios-artifact-analysis.md](snapchat-ios-artifact-analysis.md) - the full forensic methodology: timestamp reliability, media integrity, chain of custody, and keeping current.
- [sources.md](sources.md) - MITRE ATT&CK, the Lookout report, and the Snapchat-forensics research.
