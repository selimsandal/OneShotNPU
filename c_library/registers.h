#ifndef REGISTERS_H
#define REGISTERS_H

#include <stdint.h>
#include "bfloat16.h"
#include "float16.h"

// INST_DATA register, 32-bit
#define INST_DATA 0x30000000

// Scalar Registers (16-bit)
#define SCALAR_REG_0 0x30000004
#define SCALAR_REG_1 0x30000006
#define SCALAR_REG_2 0x30000008
#define SCALAR_REG_3 0x3000000A

// Vector Registers (16 * 16-bit)
#define VECTOR_REG_0 0x3000000C
#define VECTOR_REG_1 0x3000002C
#define VECTOR_REG_2 0x3000004C
#define VECTOR_REG_3 0x3000006C

void write_vector_float(bfloat16 *address, float data[16]) {
    for (int i = 0; i < 16; i++) {
        bfloat16 bfloatVal = float32_to_bfloat16(data[i]);
        *(address + i) = bfloatVal;
    }
}

void write_vector_bfloat16(bfloat16 *address, const bfloat16 data[16]) {
    for (int i = 0; i < 16; i++) {
        *(address + i) = data[i];
    }
}

void write_scalar_float(bfloat16 *address, float data) {
    *address = float32_to_bfloat16(data);
}

void write_scalar_bfloat16(bfloat16 *address, bfloat16 data) {
    *address = data;
}

void assign_instruction(uint32_t instruction) {
    *(uint32_t *) INST_DATA = instruction;
}

#endif // REGISTERS_H
