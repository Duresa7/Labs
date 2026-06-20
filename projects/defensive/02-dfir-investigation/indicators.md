# Indicators of compromise

The indicators I built from the investigation, in the OpenIOC style (the FireEye/Mandiant editor I used). The logic and the indicator types are what I actually authored. Each is shaped to catch the threat a different way, so changing one attribute does not evade detection.

## Indicator 1: known-bad file by hash

The simplest indicator, "have I seen this exact file." A single SHA-1 tied to a system file path.

```
FileItem/Sha1sum   = <sha1-hash>
FileItem/FullPath  = C:\Windows\System32\<file>.msc
```

## Indicator 2: compound file indicator

Catches a payload even if one attribute was changed, by combining attributes with AND / OR:

```
OR
├── FileItem/SizeInBytes  = 278528
├── FileItem/FileName     = <name>.exe
└── AND
    ├── FileItem/Created   = <timestamp>
    └── FileItem/Sha1sum   = <sha1-hash>
```

Match if the size equals a known value, OR the name matches, OR (the created timestamp AND the hash both match). A single-fact rule fails the moment the attacker renames the file; this one does not.

## Indicator 3: registry persistence

Catches the persistence mechanism itself rather than a specific payload, which is more durable because the payload can change while the technique stays the same:

```
AND
├── RegistryItem/Path      = HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
├── RegistryItem/ValueName = <autorun-value-name>
└── FileItem/FileName      = <referenced-executable>
```

Anything under a `...\CurrentVersion\Run` key executes at logon, so a value there pointing at an executable is the artifact this indicator flags. This is the same behavior that the file-integrity and detection rules in [the detection-engineering project](../03-detection-engineering/README.md) are built to catch from the network and host side.
