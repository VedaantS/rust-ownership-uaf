// A "growing array" use after free: no explicit free() on the line that breaks.
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *nums = malloc(2 * sizeof(int));
    nums[0] = 1;
    nums[1] = 2;

    int *first = &nums[0];                    // pointer into the old buffer
    nums = realloc(nums, 100 * sizeof(int));  // may move the array and free the old one

    printf("%d\n", *first);                   // use after free
    free(nums);
    return 0;
}
