#include <stdio.h>
#include "headers/utils.h"
#include "headers/mathutils.h"

int main(void) {
    greet();
    printf("2 + 3 = %d\n", add(2, 3));
    printf("4 * 5 = %d\n", multiply(4, 5));
    return 0;
}
