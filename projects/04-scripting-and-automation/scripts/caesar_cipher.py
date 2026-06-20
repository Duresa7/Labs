"""Caesar cipher I wrote while learning scripting.

Shifts each letter by a fixed key and wraps around the alphabet, leaving
non-letters untouched. See ../README.md for how it works and sample output.
"""


def caesar_cipher(text, key):
    text1 = ""
    for char in text:
        if char.isalpha():
            shift = ord(char) + key
            if char.islower():
                if shift > ord('z'):
                    shift -= 26
                elif shift < ord('a'):
                    shift += 26
            elif char.isupper():
                if shift > ord('Z'):
                    shift -= 26
                elif shift < ord('A'):
                    shift += 26
            text1 += chr(shift)
        else:
            text1 += char
    return text1


print(caesar_cipher("Hello World", 3))
print(caesar_cipher("Python", -2))
print(caesar_cipher("Caesar Cipher", 1))
