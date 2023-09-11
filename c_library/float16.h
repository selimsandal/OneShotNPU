#ifndef FLOAT16_H
#define FLOAT16_H

#include <stdint.h>
#include <string.h>
#include <limits.h>
#include <math.h>

typedef uint16_t float16;

float16 float_to_half(float f) {
    float16 h;
    uint32_t *x = (uint32_t *) &f;
    uint32_t i = *x;
    uint32_t sign = (i >> 31) << 15;
    int32_t exp = ((i >> 23) & 0xff) - 127;
    int32_t mant = i & 0x7fffff;

    if (exp == 128) { // infinity or NaN
        h = (float16) (sign | 0x7c00);
    } else if (exp > 15) { // overflow - flush to Infinity
        h = (float16) (sign | 0x7c00);
    } else if (exp <= -15) { // underflow - flush to zero
        h = (float16) sign;
    } else { // normal value
        h = (float16) (sign | (exp + 15) << 10 | mant >> 13);
    }

    return h;
}

float half_to_float(float16 h) {
    uint32_t sign = ((h & 0x8000) >> 15) << 31;
    int32_t exp = (h & 0x7c00) >> 10;
    int32_t mant = h & 0x03ff;

    if (exp == 0) {
        exp = -14;
    } else if (exp == 0x1f) {
        exp = 128;
    } else {
        exp += 127 - 15;
    }

    uint32_t x = sign | (exp << 23) | (mant << 13);
    float f;
    memcpy(&f, &x, sizeof(f));

    return f;
}

float16 int_to_half(int i) {

    // Handle infinity
    if (i == INT_MAX || i == INT_MIN) {
        return 0x7C00;
    }

    // Extract sign
    uint16_t sign = (i >> 31) << 15;

    // Handle zero
    if (i == 0) {
        return sign;
    }

    // Extract exponent and mantissa
    uint32_t rem = i;
    int exp = -1;
    while (rem) {
        rem >>= 1;
        exp++;
    }

    // Bias exponent
    exp += 15 - 1;
    if (exp >= 31) {
        exp = 31;
    }

    // Round mantissa
    uint32_t mant = (i >> (exp - 25)) & 0x1FFF;
    if ((i >> (exp - 25 - 1)) & 1) {
        mant += 1;
    }

    // Assemble float16
    return (float16) (sign | (exp << 10) | mant);
}

int half_to_int(float16 h) {

    // Handle NaN
    if (h > 0x7FFF) {
        return 0x80000000;
    }

    // Handle infinity
    if (h == 0x7C00) {
        return INT_MAX;
    }
    if (h == 0xFC00) {
        return INT_MIN;
    }

    // Extract components
    uint16_t sign = (h >> 15) & 1;
    uint16_t exp = (h >> 10) & 0x1F;
    uint16_t mant = h & 0x3FF;

    // Handle zero
    if (exp == 0) {
        return 0;
    }

    // Unbias exponent
    exp -= 15;

    // Shift mantissa
    uint32_t val = (mant | 0x400) << (13 + exp);

    // Apply sign
    return sign ? -val : val;

}

#endif //FLOAT16_H
