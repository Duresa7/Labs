"""Hashing demo I wrote while learning scripting.

Takes one string and prints its digest under eight algorithms so the output
sizes and the avalanche effect are easy to compare side by side. See
../README.md for sample output and a note on which of these are safe to use.
"""

import hashlib


def hash_string(input_string):
    print("MD5:", hashlib.md5(input_string.encode()).hexdigest())
    print("SHA-1:", hashlib.sha1(input_string.encode()).hexdigest())
    print("SHA-256:", hashlib.sha256(input_string.encode()).hexdigest())
    print("SHA-512:", hashlib.sha512(input_string.encode()).hexdigest())
    print("SHA3-256:", hashlib.sha3_256(input_string.encode()).hexdigest())
    print("SHA3-512:", hashlib.sha3_512(input_string.encode()).hexdigest())
    print("BLAKE2-256:", hashlib.blake2s(input_string.encode()).hexdigest())
    print("BLAKE2-512:", hashlib.blake2b(input_string.encode()).hexdigest())


input_string = input("Enter String: ")
hash_string(input_string)
