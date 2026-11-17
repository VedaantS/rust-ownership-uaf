// Use after free in C: compiles cleanly, fails at runtime.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *s = strdup("hi");
    free(s);
    printf("%s\n", s); // use after free
    return 0;
}
