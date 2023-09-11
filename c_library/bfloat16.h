#ifndef BFLOAT16_H
#define BFLOAT16_H

#include <stdint.h>
#include <math.h>

typedef uint16_t bfloat16;

bfloat16 float32_to_bfloat16(float f) {

    uint32_t x = *(uint32_t *) &f;

    // Get sign bit
    uint16_t sign = (x >> 31) & 0x1;

    // Get exponent
    uint32_t exponent = (x >> 23) & 0xFF;

    // Get mantissa
    uint32_t mantissa = x & 0x7FFFFF;

    // Check for zero/denormals
    if (exponent == 0xFF) {
        return sign ? 0xBF80 : 0x3F80;
    } else if (exponent == 0) {
        mantissa = mantissa != 0;
        exponent = 0;
    } else {
        exponent += 0x70;
    }

    // Round to nearest even
    uint32_t r = mantissa >> 16;
    mantissa += r & 1;

    // Construct bfloat16 representation
    bfloat16 result = (sign << 15) | (exponent << 7) | (mantissa >> 16);

    return result;

}

float bfloat16_to_float32(bfloat16 h) {

    // Get sign bit
    uint32_t sign = (h >> 15) & 0x1;

    // Get exponent
    uint32_t exponent = (h >> 7) & 0xFF;

    // Get mantissa
    uint32_t mantissa = h & 0x7F;

    // Check for zero/denormals
    if (exponent == 0) {
        return sign ? -0.0f : 0.0f;
    } else if (exponent == 0xFF) {
        return sign ? -INFINITY : INFINITY;
    }

    // Construct float32 representation
    exponent -= 0x70;
    mantissa <<= 16;

    uint32_t result = (sign << 31) | (exponent << 23) | mantissa;

    return *(float *) &result;

}

// Function to convert an integer to bfloat16
bfloat16 intToBfloat16(int value) {
    // Extract the sign bit
    uint16_t sign = (value < 0) ? 0x8000 : 0x0000;

    // Extract the exponent and fraction bits
    uint16_t exponentFraction = 0;
    if (value != 0) {
        int absValue = (value < 0) ? -value : value;
        int exponent = 0;
        while (absValue >= 2 && exponent < 15) {
            absValue >>= 1;
            exponent++;
        }
        exponentFraction = ((exponent + 127) << 7) | (absValue & 0x7F);
    }

    // Combine the sign, exponent, and fraction bits to form the bfloat16
    bfloat16 bf16Value = sign | exponentFraction;

    return bf16Value;
}

// Function to convert a bfloat16 to an integer
int bfloat16ToInt(bfloat16 bf16Value) {
    // Extract the sign bit
    int sign = (bf16Value & 0x8000) ? -1 : 1;

    // Extract the exponent and fraction bits
    int exponent = ((bf16Value >> 7) & 0xFF) - 127;
    int fraction = bf16Value & 0x7F;

    // Calculate the integer value
    int intValue = sign * ((1 << exponent) | fraction);

    return intValue;
}


#endif //BFLOAT16_H
