# Scripting for security and automation

Two languages from the same scripting course, kept together because they were the same skill aimed at two jobs: Python for small security and data-handling utilities, and PowerShell for automating a Windows box. The Python programs are real files you can run, in [scripts/](scripts/). The PowerShell work was a set of guided exercises, so it is written up below rather than shipped as scripts.

> **A note on names and on screenshots.** These were captured in a shared virtual desktop, and the window around the terminal carried personal and course identifiers (the desktop's bookmarks, the lab URL, my name in the file path). Rather than box all of that out of every image, I re-ran each Python program and pasted the actual output as text. The code is exactly what I wrote; the output below is real.

## Python: small security and data utilities

Four short programs, each built around one idea: shifting characters, substituting them, hashing them, and validating a format. Two of them are clean. The other two I tested properly while writing this up and found bugs, which are worth more than the working ones because of what they taught me.

### Caesar cipher

`caesar_cipher(text, key)` walks each character, and for letters it shifts the code point by the key and wraps around the end of the alphabet so `z` shifted by 3 lands back near `a`. Non-letters (spaces, punctuation) pass through unchanged, and upper and lower case are handled separately so the case is preserved.

```
$ python scripts/caesar_cipher.py
Khoor Zruog
Nwrfml
Dbftbs Djqifs
```

The wrap logic adjusts by a single 26 in each direction, so it is correct for keys roughly in the range -26 to 26, which covers every normal use. A key far outside that range would shift past the wrap; the general fix is to take the offset within the alphabet modulo 26 instead of testing the boundary once. I left the original in place because it shows the boundary problem clearly.

### Leetspeak and credit-card masking

Two functions in one program. `hacker_speak` swaps letters for look-alike digits (`a`->`4`, `e`->`3`, `i`->`1`, `o`->`0`, `s`->`5`), with an optional cap on how many of each it replaces. `credit_card` keeps only the last four digits of a 16-digit number and masks the rest, the way a receipt does, after checking the input really is 16 digits.

It runs correctly when you cap the replacements:

```
$ python scripts/hacker_speak.py
Enter text to h4ck3r 5p34k: aaaa eeee
Enter maximum number of replacements per character: 1
Hacker Speak: 4aaa 3eee
Enter your credit card number (Must be 16 digits): 4111111111111111
The last 4 digits of your Credit Card is: ************1111
```

**The bug.** Entering `-1` is meant to mean "replace every occurrence." The code turns that `-1` into `None` and passes it as the count to `str.replace`:

```python
if max_reps == -1:
    max_reps = None
...
text = text.replace(old, new, max)   # max is None here
```

`str.replace` in Python 3 wants an integer count, so `None` raises `TypeError: 'NoneType' object cannot be interpreted as an integer` and the program crashes on the most common input. The fix is to drop the `None` step entirely, because `str.replace` already treats `-1` as "replace all":

```python
def hacker_speak(text, max_reps=-1):
    replacements = [('a', '4'), ('e', '3'), ('i', '1'), ('o', '0'), ('s', '5')]
    for old, new in replacements:
        text = text.replace(old, new, max_reps)
    return text
```

With that change, `-1` replaces everything and a positive number still caps it:

```
hacker_speak("aaaa eeee oranges", -1) -> 4444 3333 0r4ng35
hacker_speak("aaaa eeee oranges", 1)  -> 4aaa 3eee 0range5
```

### Comparing hash algorithms

This one feeds a single string through eight algorithms from `hashlib` and prints each digest, so the differences are visible at a glance: the digest length per algorithm, and the fact that the same input always produces the same output.

```
$ python scripts/hashing.py
Enter String: HelloWorld
MD5: 68e109f0f40ca72a15e05cc22786f8e6
SHA-1: db8ac1c259eb89d4a131b253bacfca5f319d54f2
SHA-256: 872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4
SHA-512: 8ae6ae71a75d3fb2e0225deeb004faf95d816a0a58093eb4cb5a3aa0f197050d7a4dc0a2d5c6fbae5fb5b0d536a0a9e6b686369fa57a027687c3630321547596
SHA3-256: 964b398ecd55793d8ca93e01274efe1377a70c8dc358fdca17cb4e94a9ed7777
SHA3-512: 60846a2369ad408101216c7f952be7019559acfa146e6b5c51d0a18424a620a22e937e5650ed332cbdb9ebe21f03f86207078958e0ef7b60bb285851cf9f9a32
BLAKE2-256: fdbd2d7d53667a1d9bc747fd93bc11287bc0b07f552ed0dbffa653b24133662f
BLAKE2-512: 8dc77b2e140c3601a9fdd146684dea960124c514b999314be65fafe189cecee9bb1395cc80826aa1b8464de775678d13bfd332c51aafd026b9b5a67e606430f3
```

Printing them together is the point: MD5 is 32 hex characters (128 bits), SHA-256 is 64 (256 bits), SHA-512 and BLAKE2b are 128 (512 bits). The security caveat I would attach to this now: MD5 and SHA-1 are here only to show the format. Both have practical collision attacks and should not be used to verify integrity or sign anything. For new work the choice is SHA-256 and up, SHA-3, or BLAKE2. For password storage none of these belongs on its own; that calls for a slow, salted function such as bcrypt or Argon2.

### Validating an IPv4 address

The goal is to accept a string only if it is a real dotted-quad address: four parts split on `.`, each a number in range, no junk. The original splits on the dots, rejects anything that is not exactly four parts, and then checks each part. Testing it against a spread of inputs is where it fell apart:

```
$ python scripts/ipv4_validator.py   (run against a list of test addresses)
192.168.1.1  -> True
10.0.0.0     -> False
192.168.1.10 -> False
256.1.1.1    -> False
1.2.3        -> False
01.2.3.4     -> False
8.8.8.8      -> True
```

It correctly rejects `256.1.1.1` (out of range), `1.2.3` (too few parts), and `01.2.3.4` (leading zero). But it rejects two addresses that are perfectly valid, and that is two separate bugs:

```python
if not part.isdigit() or not 1 <= int(part) <= 255:   # bug 1
    return False
...
if i == 3 and part[-1] == '0':                         # bug 2
    return False
```

- **Bug 1** uses `1 <= int(part) <= 255`. A valid octet is `0` to `255`, so this throws out any address with a `0` octet, including a network address like `10.0.0.0`.
- **Bug 2** rejects the address if its last octet ends in the digit `0`. That kills ordinary hosts such as `192.168.1.10`, `.20`, `.100`. I think the intent was to catch a leading zero in the last octet, but it tests the wrong end of the string and the leading-zero case is already handled.

Rather than patch those line by line, the corrected version in [scripts/ipv4_validator_fixed.py](scripts/ipv4_validator_fixed.py) hands the parsing to the standard library's `ipaddress` module, which validates an address the same way the operating system does:

```python
import ipaddress

def is_valid_ipv4(ip_address):
    try:
        ipaddress.IPv4Address(ip_address)
        return True
    except ipaddress.AddressValueError:
        return False
```

Same test inputs, correct results:

```
192.168.1.1  -> True
10.0.0.0     -> True
192.168.1.10 -> True
256.1.1.1    -> False
1.2.3        -> False
01.2.3.4     -> False
8.8.8.8      -> True
```

The lesson I took from this: hand-rolled validation is where edge cases hide, and for a format with a standard parser, using that parser is both shorter and more correct than the rules I would write from memory.

## PowerShell: Windows automation fundamentals

The PowerShell half of the course built up the pieces you string together to automate administration on Windows. I worked through these in order, each as a small hands-on exercise:

- **Getting oriented.** `Get-Help` for any cmdlet, `Update-Help` to pull the current help files, and `$PSVersionTable` to confirm the version of the environment I was in.
- **Files and folders.** Creating, copying, moving, renaming, and deleting both files and folders with `New-Item`, `Copy-Item`, `Move-Item`, `Rename-Item`, and `Remove-Item`, then confirming existence with `Test-Path` and reading items back with `Get-Item`.
- **Reading and writing file content across formats.** Writing and reading plain text, CSV, XML, and HTML; appending with `Add-Content`; and clearing a file with `Clear-Content`. Treating CSV and XML as first-class showed how PowerShell moves structured data, not just strings.
- **Variables and objects.** Assigning values such as `$location = Get-Location`, using them, and inspecting what a value actually is with `Get-Member`. That last cmdlet is the one that made PowerShell click: everything is an object with properties and methods, not flat text.
- **Operators.** Arithmetic, comparison (`-eq`, `-lt`, `-gt`), assignment, logical (`-and`, `-or`, `-not`), and the miscellaneous set, which is where PowerShell differs most from a C-style language.
- **Control flow.** `for`, `foreach`, `while`, and `do...while` loops; and `if`, `if...else`, nested `if`, and `switch` for branching.
- **Arrays.** Declaring them, indexing and iterating over them, and using their built-in methods.

Representative examples of the constructs above:

```powershell
# create a file, write to it, read it back
New-Item C:\temp\test\test.txt
Set-Content C:\temp\test\test.txt 'Welcome to scripting'
Get-Content C:\temp\test\test.txt

# inspect what a value really is
$location = Get-Location
$location | Get-Member

# loop over an array
$array = @("item1", "item2", "item3")
for ($i = 0; $i -lt $array.length; $i++) { Write-Output $array[$i] }

# branch on a value
switch ($day) {
    "Sat" { "weekend" }
    "Sun" { "weekend" }
    default { "weekday" }
}
```

These are fundamentals rather than a finished tool, but they are the building blocks behind the real automation in my other repos: the scheduled jobs in [Homelab-Project](https://github.com/Duresa7/Homelab-Project) and the host setup work in this lab all come down to the same loops, conditionals, and file handling practiced here. The PowerShell side gets applied to a real administrative task in [project 05, Windows patch management](../05-windows-patch-management/README.md).

## Files in this project

- [scripts/caesar_cipher.py](scripts/caesar_cipher.py) - shift cipher with alphabet wrap-around.
- [scripts/hacker_speak.py](scripts/hacker_speak.py) - leetspeak converter and credit-card masker (original, with the documented bug).
- [scripts/hashing.py](scripts/hashing.py) - one string through eight hash algorithms.
- [scripts/ipv4_validator.py](scripts/ipv4_validator.py) - the original IPv4 validator (with the two documented bugs).
- [scripts/ipv4_validator_fixed.py](scripts/ipv4_validator_fixed.py) - the corrected validator built on the `ipaddress` module.
- [sources.md](sources.md) - the references I used.
