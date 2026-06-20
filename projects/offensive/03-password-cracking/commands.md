# Command reference

The dictionary attack I ran against a mixed set of hashes:

```bash
# -m 0  = the hashes are MD5
# -a 0  = straight dictionary attack (hash each word, compare)
hashcat -m 0 -a 0 -o cracked.txt target_hashes.txt wordlist.txt
```

## The lesson hidden in the flags

`target_hashes.txt` held ten hashes across several algorithms (MD2, MD5, SHA-1, SHA-256). Because the run specified `-m 0` (MD5), only the MD5 entries matched; the others could not, since an MD5 of a word never equals that word's SHA-256. To attack the others you change the mode:

| Hash type | `-m` mode |
|---|---|
| MD5 | `-m 0` |
| SHA-1 | `-m 100` |
| SHA-256 | `-m 1400` |
| NTLM | `-m 1000` |
| bcrypt | `-m 3200` |

So step zero of any crack is identifying the algorithm (by length, format, and context); get it wrong and a crackable password looks uncrackable.

## Attack modes

| Mode | Name | What it does |
|---|---|---|
| `-a 0` | Straight | hash each word in a wordlist |
| `-a 1` | Combination | concatenate words from two lists |
| `-a 3` | Brute / mask | every string matching a pattern, e.g. `?u?l?l?l?l?d?d` |
| `-a 6` / `-a 7` | Hybrid | wordlist plus brute-forced characters appended/prepended |

The full reasoning, including why fast hashes (MD5) fall in seconds while salted slow KDFs (bcrypt, scrypt, Argon2) do not, is in the [project README](README.md).
