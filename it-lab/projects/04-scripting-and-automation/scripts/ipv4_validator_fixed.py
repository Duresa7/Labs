"""Corrected IPv4 validator.

The original (ipv4_validator.py) rejected valid addresses. This version uses the
standard library's ipaddress module, which parses the address the same way the
operating system does: octets 0-255, no leading zeros, exactly four parts.
"""

import ipaddress


def is_valid_ipv4(ip_address):
    try:
        ipaddress.IPv4Address(ip_address)
        return True
    except ipaddress.AddressValueError:
        return False


user_input = input("Please enter an IPv4 address: ")
if is_valid_ipv4(user_input):
    print("The IP address is valid.")
else:
    print("The IP address is not valid.")
