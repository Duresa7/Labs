# Snapchat iOS artifact analysis

A methodology for recovering and validating Snapchat artifacts from an iOS device, written around the hard parts of an ephemeral, partly-encrypted app. It is organized as the four questions an examiner has to answer before the evidence is worth anything.

## 1. Are the timestamps reliable?

Snapchat's iOS database `scdb-27.sqlite3` records more than one time per item. The `ZGALLERYENTRY` and `ZGALLERYSNAP` tables hold metadata for Snaps, including a capture time (when the Snap was taken) and a created time (when it was saved or synced to the gallery). Having both lets you separate when content was produced from when it landed in storage.

The values are stored as Unix epoch, usually in milliseconds, so they have to be divided by 1000 before converting to a date. When the device clock is accurate the times line up well with real events, and because Snapchat writes them locally (they persist even in airplane mode) they are generated on the device rather than pulled from a server, which makes them useful for a local timeline.

The caution: a wrong or manipulated device clock skews every value. Treat the times as reliable only after accounting for time zone and clock state, and cross-reference them against independent evidence such as iOS system logs or the EXIF data of associated photos.

## 2. Is the recovered media intact and correctly attributed?

Recovered images and videos, including those from the encrypted gallery, have to be shown to be unaltered and tied to the right account.

- **Decrypt with the app's own keys.** On iOS the saved-media ("Memories") encryption keys live in `gallery.encrypteddb`, secured in the keychain. A clean decryption is itself an integrity signal: under AES with integrity checking, a single flipped bit would break it.
- **Hash before and after.** Compute a hash (for example SHA-256) at acquisition and again after extraction to prove the file did not change, and confirm the file's internal structure by opening the image or playing the video through.
- **Tie the file to the database.** Take the file's `EXTERNAL_KEY`, look it up in `cache_controller.db`, and follow it into `scdb-27.sqlite3`: in `ZGALLERYENTRY` the key appears as `ZENTRYID` and maps to the timestamps and the owning user ID; in `ZGALLERYSNAP` it appears as `ZSNAPID` / `ZMEDIAID` with properties like media type and whether the Snap carried location. Matching IDs and attributes is what links the media to the account.

## 3. Will it hold up in court?

Chain of custody starts at seizure and never breaks:

- Collect the device with minimal disturbance; log its condition, the date and time, and every person who handles it.
- Isolate it immediately (airplane mode or a Faraday bag) so Snapchat cannot sync deletions or take a remote wipe, which matters more here than on most apps because the data is transient by design.
- Image with a trusted full-file-system method (the Snapchat container and keychain are the targets), then hash the image so you can later prove it stayed intact.
- Preserve the original image read-only, work only on copies, and log every access or transfer.
- Document the tools and their versions, validate key findings with a second method or tool, and stay strictly within the warrant's scope.

Validated methods plus an unbroken custody record are what let an examiner testify to the data's authenticity.

## 4. How do you keep the methodology current?

Snapchat changes its schema and file locations often enough that old analyses go stale, so the methodology has to be maintained, not memorized:

- Follow current DFIR research: practitioner blogs, whitepapers, conference talks, and the newsletters that aggregate them.
- Track the forensic-tool vendors' release notes and advisories, since they update when Snapchat changes its encryption or storage.
- Keep test devices or accounts to generate known content and map new artifacts against each app version before a real case depends on it.
