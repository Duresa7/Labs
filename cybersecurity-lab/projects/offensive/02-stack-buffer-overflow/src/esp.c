/* esp.c -- prints the current stack pointer so I could watch ASLR move it.
 * Run it several times with randomize_va_space=1 (address changes) and again
 * with randomize_va_space=0 (address constant) to see what ASLR does.
 *   gcc -o esp esp.c
 */
#include <stdio.h>

void main() {
    register int i asm("esp");
    printf("$esp = %#010x\n", i);
}
