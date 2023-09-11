# NPU Spec: bfloat16, SIMD, Power-efficient

#### You:
Write specs for an NPU, this NPU will have 16 vector registers and 16 scalar registers. It will use bfloat16 as the native data type.

#### ChatGPT:
**Neural Processing Unit (NPU) Specification**

---

**1. Overview**

The NPU is a specialized processor optimized for accelerating neural network computations and other related workloads. It is designed with a focus on power efficiency and high-throughput operations, leveraging both scalar and vector processing capabilities.

---

**2. Data Type Support**

- **Primary Data Type**: bfloat16 (Brain Floating Point Format)
  - 1-bit sign, 8-bit exponent, 7-bit fraction
  - Provides a good trade-off between precision and range, optimized for deep learning workloads.

---

**3. Register Architecture**

- **Vector Registers (V-Registers)**:
  - Total: 16
  - Each V-Register can hold multiple bfloat16 values, allowing for Single Instruction Multiple Data (SIMD) operations. The exact number of bfloat16 values a V-Register can hold would depend on the width of the register. For instance, if each V-Register is 256-bits wide, it can hold 16 bfloat16 values.
- **Scalar Registers (S-Registers)**:
  - Total: 16
  - Each S-Register can hold a single bfloat16 value. Designed primarily for scalar operations and addressing.

---

**4. Core Features**

1. **SIMD Operations**: Support for operations that can act on multiple data points in parallel, leveraging the V-Registers.

2. **Fused Multiply-Add (FMA) Operations**: Capability to perform multiplication and addition in a single step, which is a common operation in neural network computations.

3. **Hardware-based Activation Functions**: Accelerated performance for commonly used activation functions like ReLU, sigmoid, and tanh.

4. **Efficient Memory Access**: Optimized for high bandwidth and low latency access to memory, crucial for neural network weights and activations.

5. **Dynamic Precision Scaling**: Ability to adjust the precision of computations on-the-fly to trade-off between accuracy and speed.

6. **Tight Integration with CPU**: Enables seamless offloading of tasks between the NPU and the central processing unit (CPU).

---

**5. Power & Performance**

- **Low-power Operations**: Optimized for power efficiency, making it suitable for both edge devices and data center deployments.

- **Thermal Management**: Advanced thermal monitoring and power gating techniques to ensure sustained performance without overheating.

---

**6. Software & Ecosystem Support**

- **NPU Instruction Set**: A rich set of instructions tailored for neural network operations and other related workloads.

- **Software Libraries**: Comprehensive set of libraries to support popular deep learning frameworks like TensorFlow, PyTorch, etc.

---

**7. Scalability**

- Modular architecture to support stacking of multiple NPUs for larger-scale operations and computations.

---

**Notes**:

The above specification provides a high-level overview of the proposed NPU. Detailed architectural designs, memory hierarchies, I/O handling, clock speeds, and other specifications would be necessary for a comprehensive hardware design and manufacturing.


#### You:
Design a simple ISA for this NPU. Write specs for each module. This NPU will receive instructions from a RISC-V cpu via a wishbone bus.

The NPU will have these signals from the wishbone bus:

input wb_clk_i, input wb_rst_i, input wbs_stb_i, input wbs_cyc_i, input wbs_we_i, input [3:0] wbs_sel_i, input [31:0] wbs_dat_i, input [31:0] wbs_adr_i, output wbs_ack_o, output [31:0] wbs_dat_o

Register starting addresses are defined like this in C.

// INST_DATA register, 32-bit
#define INST_DATA 0x30000000

// Scalar Registers (16-bit)
#define SCALAR_REG_0    0x30000004
#define SCALAR_REG_1    0x30000006
#define SCALAR_REG_2    0x30000008
#define SCALAR_REG_3    0x3000000A
#define SCALAR_REG_4    0x3000000C
#define SCALAR_REG_5    0x3000000E
#define SCALAR_REG_6    0x30000010
#define SCALAR_REG_7    0x30000012
#define SCALAR_REG_8    0x30000014
#define SCALAR_REG_9    0x30000016
#define SCALAR_REG_10   0x30000018
#define SCALAR_REG_11   0x3000001A
#define SCALAR_REG_12   0x3000001C
#define SCALAR_REG_13   0x3000001E
#define SCALAR_REG_14   0x30000020
#define SCALAR_REG_15   0x30000022

// Vector Registers (16 * 16-bit)
#define VECTOR_REG_0    0x30000024
#define VECTOR_REG_1    0x30000044
#define VECTOR_REG_2    0x30000064
#define VECTOR_REG_3    0x30000084
#define VECTOR_REG_4    0x300000A4
#define VECTOR_REG_5    0x300000C4
#define VECTOR_REG_6    0x300000E4
#define VECTOR_REG_7    0x30000104
#define VECTOR_REG_8    0x30000124
#define VECTOR_REG_9    0x30000144
#define VECTOR_REG_10   0x30000164
#define VECTOR_REG_11   0x30000184
#define VECTOR_REG_12   0x300001A4
#define VECTOR_REG_13   0x300001C4
#define VECTOR_REG_14   0x300001E4
#define VECTOR_REG_15   0x30000204

When the wbs_adr_i is set to register locations CPU should be able to read that register from wbs_dat_o, or write to it using wbs_dat_i.

#### ChatGPT:
**NPU Instruction Set Architecture (ISA) Specification**

---

**1. Overview**

The ISA provides a standardized way for the RISC-V CPU to interface and instruct the NPU via the Wishbone bus.

---

**2. Wishbone Bus Interface**

*Signals*:

- `wb_clk_i`: Clock input
- `wb_rst_i`: Reset input
- `wbs_stb_i`: Strobe signal indicating valid bus cycle
- `wbs_cyc_i`: Cycle frame signal
- `wbs_we_i`: Write enable signal
- `wbs_sel_i`: Select lines for data transfer granularity (byte, half-word, word)
- `wbs_dat_i`: Data input from the CPU to the NPU
- `wbs_adr_i`: Address input from the CPU to the NPU
- `wbs_ack_o`: Acknowledgment signal from NPU to CPU
- `wbs_dat_o`: Data output from the NPU to the CPU

---

**3. Register Addresses**

You've provided the memory mapped addresses for the `INST_DATA`, scalar registers, and vector registers.

---

**4. Instruction Data**

The `INST_DATA` register serves as the main entry point for sending instructions to the NPU:

*Operation*:

1. CPU writes a 32-bit instruction word into `INST_DATA`.
2. NPU decodes and executes the instruction.

---

**5. Scalar Register Operations**

Scalar registers store individual bfloat16 values:

*Reading*:

1. CPU sets `wbs_adr_i` to the address of the desired scalar register.
2. NPU sets `wbs_dat_o` with the content of the scalar register.
3. NPU sends acknowledgment via `wbs_ack_o`.

*Writing*:

1. CPU sets `wbs_adr_i` to the address of the target scalar register.
2. CPU sets `wbs_dat_i` with the bfloat16 data to be written.
3. NPU writes to the scalar register.
4. NPU sends acknowledgment via `wbs_ack_o`.

---

**6. Vector Register Operations**

Vector registers store multiple bfloat16 values:

*Reading*:

1. CPU sets `wbs_adr_i` to the starting address of the desired vector register.
2. For each bfloat16 entry in the vector register, the NPU sets `wbs_dat_o` with the content and waits for an acknowledgment.
3. NPU sends acknowledgment via `wbs_ack_o`.

*Writing*:

1. CPU sets `wbs_adr_i` to the starting address of the target vector register.
2. CPU sets `wbs_dat_i` with the bfloat16 data for each position in sequence.
3. NPU writes to the vector register for each position in sequence.
4. NPU sends acknowledgment via `wbs_ack_o`.

---

**7. Instruction Decoding**

The NPU will need to decode the instruction word written into `INST_DATA`. Instructions could include:

- Vector-vector arithmetic (e.g., vector addition, subtraction)
- Scalar-vector arithmetic (e.g., scalar multiplication across a vector)
- Specialized operations (e.g., dot product, matrix multiplication)

The exact format and encoding of these instructions would need to be defined based on the desired functionality of the NPU.

---

**Notes**:

This provides a high-level specification of the NPU's ISA. The actual implementation would involve deeper considerations, like:

- Error handling (what if an invalid address is specified?)
- Pipelining and concurrent operation handling
- Instruction formats and exact opcodes for operations
- Potential expansion capabilities for future enhancements

Integration with the RISC-V CPU and Wishbone bus would require compatibility with their timing, signaling, and protocol requirements. Detailed testing would be crucial to ensure robust and efficient operation.
