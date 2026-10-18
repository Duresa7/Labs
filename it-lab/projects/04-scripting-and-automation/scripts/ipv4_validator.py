"""IPv4 validator I wrote while learning scripting.

Checks that a string is a well-formed dotted-quad address. This is the original
version, and testing it later showed it rejects valid addresses. ../README.md
walks through the two bugs and the corrected version that replaced it.
"""


def is_valid_ipv4(ip_address):
    parts = ip_address.split('.')
    if len(parts) != 4:
        return False
    for i, part in enumerate(parts):
        if not part.isdigit() or not 1 <= int(part) <= 255:
            return False
        if part[0] == '0':
            return False
        if i == 3 and part[-1] == '0':
            return False
    return True


user_input = input("Please enter an IPv4 address: ")
if is_valid_ipv4(user_input):
    print("The IP address is valid.")
else:
    print("The IP address is not valid.")
