/* bo1.c -- a deliberately vulnerable program for the overflow lab.
 * copier() copies an argument into a fixed 100-byte buffer with strcpy(),
 * which performs no bounds check. An argument longer than the buffer plus
 * the saved frame overwrites the saved return address.
 *
 * Built with protections OFF on purpose, to study the overflow itself:
 *   gcc -g -z execstack -no-pie -o bo1 bo1.c
 * On a normally compiled program the stack canary aborts before the corrupted
 * return address is ever used.
 */
#include <string.h>
#include <stdio.h>

void main(int argc, char *argv[]) {
    copier(argv[1]);
    printf("Done!\n");
}

void copier(char *str) {
    char buffer[100];
    strcpy(buffer, str);   /* the vulnerability: no length check */
}
