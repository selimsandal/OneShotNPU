#ifndef FLOAT16_TEST_H
#define FLOAT16_TEST_H

#include <stdio.h>
#include "float16.h"

// Function to convert a 16-bit integer to its binary representation
void print_binary(uint16_t num) {
    for (int i = 15; i >= 0; i--) {
        printf("%d", (num >> i) & 1);
    }
}

void float16_float_test() {
    float input_float;
    float16 half;
    float output_float;

    // Test cases
    input_float = 1.0f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half: 0x%04x, Converted Back to Float: %f\n", input_float, half,
           output_float);

    input_float = -1.0f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half: 0x%04x, Converted Back to Float: %f\n", input_float, half,
           output_float);

    input_float = 3.14f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half: 0x%04x, Converted Back to Float: %f\n", input_float, half,
           output_float);

    input_float = 12345.6789f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half: 0x%04x, Converted Back to Float: %f\n", input_float, half,
           output_float);

    input_float = -0.000123f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half: 0x%04x, Converted Back to Float: %f\n", input_float, half,
           output_float);

    input_float = 234.0f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half (binary): ", input_float);
    print_binary(half);
    printf(", Converted Back to Float: %f\n", output_float);

    input_float = 547.34f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half (binary): ", input_float);
    print_binary(half);
    printf(", Converted Back to Float: %f\n", output_float);

    input_float = 6575.32f;
    half = float_to_half(input_float);
    output_float = half_to_float(half);
    printf("Input Float: %f, Converted to Half (binary): ", input_float);
    print_binary(half);
    printf(", Converted Back to Float: %f\n", output_float);
}

void float16_int_test() {
    int i;
    float16 half;

    // Test NaN handling
    i = 0x7FFFFFFF;  // NaN value
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X (Expected: 0x7FFF)\n", i, half);

    // Test infinity handling
    i = INT_MAX;  // Positive infinity
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X (Expected: 0x7C00)\n", i, half);

    i = INT_MIN;  // Negative infinity
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X (Expected: 0xFC00)\n", i, half);

    // Test zero handling
    i = 0;  // Zero
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X (Expected: 0x0000)\n", i, half);

    // Test normal cases
    i = 12345;  // A positive integer
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X\n", i, half);

    i = -54321;  // A negative integer
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X\n", i, half);

    // Test rounding
    i = 1025;  // Close to half
    half = int_to_half(i);
    printf("int_to_half(%d) = 0x%X (Expected: 0x3401)\n", i, half);

    // Test cases for half_to_int
    float16 h;
    int result;

    // Test NaN handling
    h = 0x7FFF;  // NaN value
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d (Expected: 0x80000000)\n", h, result);

    // Test infinity handling
    h = 0x7C00;  // Positive infinity
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d (Expected: %d)\n", h, result, INT_MAX);

    h = 0xFC00;  // Negative infinity
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d (Expected: %d)\n", h, result, INT_MIN);

    // Test zero handling
    h = 0x0000;  // Zero
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d (Expected: 0)\n", h, result);

    // Test normal cases
    h = 0x3401;  // A positive half-precision float
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d\n", h, result);

    h = 0xB481;  // A negative half-precision float
    result = half_to_int(h);
    printf("half_to_int(0x%X) = %d\n", h, result);
}

#endif // FLOAT16_TEST_H
