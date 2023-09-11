#ifndef BFLOAT16_TEST_H
#define BFLOAT16_TEST_H

#include <stdio.h>
#include "bfloat16.h"

void printBinary(uint32_t num, int numBits) {
    for (int i = numBits - 1; i >= 0; i--) {
        putchar((num & (1U << i)) ? '1' : '0');
        if (i % 8 == 0) {
            putchar(' ');
        }
    }
}

void bfloat16_float_test() {
    float test_cases[] = {1.0f, -2.5f, 123.456f, -789.123f, 0.0001f, 1.0e20f, -1.0e-20f};
    int num_test_cases = sizeof(test_cases) / sizeof(test_cases[0]);

    for (int i = 0; i < num_test_cases; i++) {
        float original_float = test_cases[i];
        bfloat16 bfloat_val = float32_to_bfloat16(original_float);
        float converted_float = bfloat16_to_float32(bfloat_val);

        printf("Test Case %d:\n", i + 1);
        printf("Original float: %f\n", original_float);
        printf("Original float (Binary): ");
        printBinary(*(uint32_t *) &original_float, 32);
        printf("\n");
        printf("Converted bfloat16: 0x%04X\n", bfloat_val);
        printf("Converted bfloat16 (Binary): ");
        printBinary(bfloat_val, 16);
        printf("\n");
        printf("Converted back to float: %f\n", converted_float);

        // Check if the conversion is within a tolerance (e.g., 1e-6)
        float tolerance = 1e-6;
        if (fabsf(original_float - converted_float) <= tolerance) {
            printf("Conversion is within tolerance.\n");
        } else {
            printf("Conversion is NOT within tolerance.\n");
        }
        printf("\n");
    }
}

void bfloat16_int_test() {

}

#endif //BFLOAT16_TEST_H
