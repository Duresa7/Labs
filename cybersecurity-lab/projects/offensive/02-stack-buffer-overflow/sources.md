# Sources

- **The source code I wrote is in [`src/`](src/):** `esp.c` (observe ASLR), `bo1.c` (the vulnerable program), and `overflow.py` (the 116-byte crash input).
- **Linux kernel, `randomize_va_space` (ASLR).** `https://www.kernel.org/doc/Documentation/sysctl/kernel.txt`
  The `/proc/sys/kernel/randomize_va_space` toggle used to turn ASLR on and off.
- **GCC, stack-protection options (`-fstack-protector`, `-z execstack`, `-no-pie`).** `https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html`
  The protections I had to disable to study the overflow, and the canary that stops it when left on.
- **OWASP, "Buffer Overflow" and the C `strcpy` weakness (CWE-120 / CWE-787).** `https://owasp.org/www-community/vulnerabilities/Buffer_Overflow` , `https://cwe.mitre.org/data/definitions/120.html`
  The vulnerability class and the unbounded-copy root cause.
- **"Smashing the Stack for Fun and Profit" (Aleph One, Phrack 49).** `http://phrack.org/issues/49/14.html`
  The classic explanation of how a stack overflow overwrites the saved return address.
- **Completed local overflow screenshot set.**
  Source for the ASLR, vulnerable-program, and crash evidence in `evidence/`. Raw source folder names and source labels are not published.
