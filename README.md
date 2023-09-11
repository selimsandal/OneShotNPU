# OneShotNPU

OneShotNPU is a Neural Processing Unit that aims to accelerate common machine learning workloads, all design rtl of this NPU is generated by AI with a single prompt.

### Contributors

- Selim Sandal undergraduate 2. year computer engineering student at Ozyegin University
- Yusuf Can Akbas undergraduate 2. year computer engineering student at Yildiz Technical University

## Our Aim, Why OneShot?

Currently, using LLMs for digital design is limited to coding assistants. We wanted to explore LLMs' abilities for rapid design exploration, in this case, we designed a single prompt consisting of specifications to build an entire design in one shot.

All functional RTL of this NPU is generated by a single prompt using an open-source Large Language Model.  

After generating the full SystemVerilog code, we asked GPT-4 to help with 2d arrays (since Yosys doesn't support those) and simple fixes (missing parentheses and signal name confusions). Then we converted our SystemVerilog modules to Verilog using sv2v and ran the flow.

## Important Directories and Files

- You can find specification generation, testbench, bugfix, and physical design prompts under [prompts](https://repositories.efabless.com/selimsandal/OneShotNPU/blob/main/f/prompts) folder.

- NPU source code is in `verilog/rtl/npu.sv`.

- `verilog/rtl/npu_v.v` is npu.sv converted from SystemVerilog to Verilog using sv2v.

- You can find our inference scripts and parameters under `inference_scripts` folder.

## Model selection

We experimented with ChatGPT (GPT-3), ChatGPT Plus (GPT-4), codellama and WizardCoder.

### Specification Generation

For spec generation, GPT-4 is the best option. While designing the NPU, we generated the full specs using GPT-4 and refined the generated ISA and specifications for our design.

### RTL generation

For RTL generation, 2 models stand out. GPT-4 is excellent for experimenting with minimal specs but cannot generate complete modules when requesting multiple modules. Because of that, we need to use various chats (to reset the context), which leads to GPT-4 failing to know which signals to connect.

After generating parts of the NPU with GPT-4, we tried the single prompt idea and selected the newly released [WizardCoder](https://huggingface.co/WizardLM/WizardCoder-Python-34B-V1.0). Wizardcoder supports context length up to 16k tokens, making it ideal for generating multiple modules. Of course, some things could be improved in WizardCoder, too. When experimenting with the OneShot prompt, WizardCoder can hallucinate Wishbone or other modules' ports if ports are not specified. To overcome this, we specified ports of the modules we wanted to generate.

There are multiple versions of [quantized WizardCoder](https://huggingface.co/TheBloke/WizardCoder-Python-34B-V1.0-GGUF) models. We chose wizardcoder-python-34b-v1.0.Q6_K.gguf. We chose a quantized version of the model because of the memory restrictions of our inference system.

### OneShot Prompt

We experimented with different versions of the prompt, you can find some old versions and the full final prompt+response here:

- [Old prompt 1](https://repositories.efabless.com/selimsandal/OneShotNPU/blob/main/f/prompts/old_prompt.txt)
- [Old prompt 2](https://repositories.efabless.com/selimsandal/OneShotNPU/blob/main/f/prompts/old_prompt_2.txt)
- [Final prompt](https://repositories.efabless.com/selimsandal/OneShotNPU/blob/main/f/prompts/OneShot_prompt_and_response.txt):

```verilog
"Implement these modules for an NPU coprocessor. This NPU uses bfloat16 as the native data type. This NPU receives commands and data via a wishbone bus from the RISC-V cpu. This NPU accelerates vector-vector and vector-scalar addition, subtraction, multiplication, division.

bfloat16 has the following format:

Sign bit: 1 bit
Exponent width: 8 bits
Significand precision: 8 bits (7 explicitly stored, with an implicit leading bit), as opposed to 24 bits in a classical single-precision floating-point format

1. bfloat16_addsub
ports:
    input logic [15:0] a,
    input logic [15:0] b,
    output logic [15:0] result,
    input is_sub

explanation:
Extract the sign of the result from the two sign bits.
Subtract the two exponents  E_a and  E_b . Find the absolute value of the exponent difference ( E ) and choose the exponent of the greater number.
Shift the mantissa of the lesser number by  E bits Considering the hidden bits.
Execute addition or subtraction operation between the shifted version of the mantissa and the mantissa of the other number. Consider the hidden bits also.
Normalization for addition: In case of addition, if there is an carry generated then the result right shifted by 1-bit. This shift operation is reflected on exponent computation by an increment operation.
Normalization for subtraction: A normalization step is performed if there are leading zeros in case of subtraction operation. Depending on the leading zero count the obtained result is left shifted. Accordingly the exponent value is also decremented by the number of bits equal to the number of leading zeros.

2. bfloat16_mul

ports:
    input logic [15:0] a,
    input logic [15:0] b,
    output logic [15:0] result

explanation:
Extract the sign of the result from the two sign bits.
Add the two exponents ( E ). Subtract the bias component from the summation.
Multiply mantissa of  b ( M_b ) by mantissa of a ( M_a ) considering the hidden bits.
If the MSB of the product is  \lq 1\rq \hspace{1pt} then shift the result to the right by 1-bit.
Due to this, the exponent is to be incremented according to the one bit right shift.

3. bfloat16_div

ports:
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] result

explanation:
Extract the sign of the result from the two sign bits.
Find the magnitude of the difference between two exponents ( E ). Add  E to the bias if E_b>E_a or subtract  E from the bias if  E_b<E_a.
Divide mantissa of  b ( M_b ) by mantissa of  a ( M_a) considering the hidden bits.
If there is a leading zero then normalize the result by shifting it left.
Due to the normalization, the exponent is to be decremented according to the number of left shifts.

4. vector_regs

ports:
    input logic clk,
    input rst,

    input [1:0] read_addr,
    output logic [15:0] read_data, //partial read

    input we, //write enable,
    input [5:0] write_addr, //2 bits register select, 4 bits element select
    input [15:0] write_data, //partial write

    input full_we, //full write enable
    input [255:0] full_write_data
    

explanation: 4 vector registers that each store 16 bfloat16 values, partial writes target 16 bit elements, full writes target a full register, full writes ignore last 4 bits of write_addr.

5. scalar_regs

ports:
    input logic clk,
    input rst,

    input [1:0] read_addr_a,
    input [1:0] read_addr_b,
    output logic [15:0] read_data,

    input we, //write enable
    input [1:0] write_addr,
    input [15:0] write_data


explanation: 4 scalar registers that each store 1 bfloat16 value, reads and writes are 16 bits wide.

6. processing_element

ports:
    input logic clk,
    input rst,
    input [3:0] opcode,
    input [15:0] a_in,
    input [15:0] b_in,
    output logic [15:0] result

explanation: instantiates bfloat16 operation modules and outputs the correct result according to opcode.

processing element opcodes:
0001: add
0010: subtract
0011: multiply
0100: divide

7. instruction_decoder:

ports:
    input [31:0] inst,
    output logic [3:0] opcode,
    output logic [1:0] src1,
    output logic [1:0] src2,
    output logic [1:0] dest

explanation: decodes the instruction for control module

8. control_module

opcodes:

execution operations:
0001: vector-vector add
0010: vector-scalar add
0011: vector-vector subtract
0100: vector-scalar subtract
0101: vector-vector multiply
0110: vector-scalar multiply
0111: vector-vector divide
1000: vector-scalar divide

data operations:
1001: load vector element
1010: read vector element
1011: load scalar register
1100: read scalar register

ports:
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o

explanation: instantiates instruction_decoder, scalar_regs, vector_regs, 16 processing_elements.

For execution operations first 2 bits of the addresses will be used, an instruction will be received from wbs_dat_i, this instruction will be decoded by instruction_decedor. For vector-vector operations starting from processing_element 1, 16 bit elements of the registers will be sent to processing_elements, after execution the result will be concatenated and written back to the destination vector register using the full write port. For vector scalar operations, required registers will be fetched from scalar and vector registers, 16 bit elements of the registers will be sent to a_in ports of the processing elements, all b_in ports will be set to the value from the scalar register, after execution the result will be concatenated and written back to the destination vector register.

For read and write operation of vector registers all 6 bits of the address will be sent to write_addr.
For read opcodes, the register value will be sent to wbs_dat_o.
For load opcodes, the immediate value will be loaded into the specified register. Vector load operations will use partial write port."
```


## ISA (Generated by GPT-4)

### Instruction Format

| Bit Position   | 31-29 | 28-24 | 23-19 | 18-17 | 16-0   |
|----------------|-------|-------|-------|-------|-------|
| Field Name     | opcode| src1  | src2  | dest  | immediate |

### Execution Operations

| Opcode | Execution Operation     |
|--------|-------------------------|
| 0001   | vector-vector add       |
| 0010   | vector-scalar add       |
| 0011   | vector-vector subtract  |
| 0100   | vector-scalar subtract  |
| 0101   | vector-vector multiply  |
| 0110   | vector-scalar multiply  |
| 0111   | vector-vector divide    |
| 1000   | vector-scalar divide    |

### Data Operations

| Opcode | Data Operation          |
|--------|-------------------------|
| 1001   | load vector element     |
| 1010   | read vector element     |
| 1011   | load scalar register    |
| 1100   | read scalar register    |

### Processing Operations

| Opcode | Processing Operation |
|--------|----------------------|
| 0001   | add                  |
| 0010   | subtract             |
| 0011   | multiply             |
| 0100   | divide               |

## Module Specifications

These specifications are generated with GPT-4.

### bfloat16_addsub

#### Overview

The `bfloat16_addsub` module performs addition or subtraction on two bfloat16 format numbers, depending on the `is_sub` input. The bfloat16 format is a 16-bit wide floating-point format consisting of 1 sign bit, 8 exponent bits, and 7 mantissa bits.

#### Parameters

- `WIDTH`: The width of the input and output numbers. The default value is 16 for bfloat16.

#### Ports
**Inputs**:

- `a`: A `WIDTH`-bit wide input representing the first bfloat16 number.
- `b`: A `WIDTH`-bit wide input representing the second bfloat16 number.
- `is_sub`: A single-bit input signal. If `is_sub` is `1`, subtraction is performed; if `0`, addition is executed.

**Outputs**:

- `result`: A `WIDTH`-bit wide output representing the result of the addition or subtraction operation between `a` and `b.`

#### Detailed Description

1. **Sign Bit Calculation**:
    - The sign bit of the result is computed using an XOR between the sign bit of `a` and an AND operation between the `is_sub` and the sign bit of `b`.

2. **Exponent Calculation**:
    - The exponents from `a` and `b` are subtracted, and the absolute value of the difference is computed. This gives an idea of which number is larger in magnitude and by how much.

3. **Mantissa Shifting**:
    - Depending on which exponent is larger, the mantissa of the smaller number is shifted right by the absolute value of the exponent difference (`E`).

4. **Addition/Subtraction**:
    - Depending on the `is_sub` input, the shifted mantissas are either added or subtracted.

5. **Result Normalization**:
    - The resulting mantissa from the addition or subtraction may need to be normalized. If the MSB of the resulting mantissa is `0`, the value is less than 1 and needs to be shifted until the MSB is `1`. The exponent is adjusted accordingly.

---

### bfloat16_mul

#### Overview
The `bfloat16_mul` module performs a multiplication operation on two bfloat16 format numbers. The bfloat16 format is a 16-bit wide floating-point format comprising 1 sign bit, 8 exponent bits, and 7 mantissa bits.

#### Parameters
- `WIDTH`: The width of the input and output numbers. The default value is 16 for bfloat16.

#### Ports
**Inputs**:

- `a`: A `WIDTH`-bit wide input representing the first bfloat16 number.
- `b`: A `WIDTH`-bit wide input representing the second bfloat16 number.

**Outputs**:

- `result`: A `WIDTH`-bit wide output representing the multiplication result of `a` and `b` in bfloat16 format.

#### Detailed Description
1. **Sign Bit Calculation**:
    - The sign bit of the result is computed using the XOR of the sign bits of the two input numbers. This is based on the floating-point multiplication property: If the signs of the two numbers are the same, the result is positive; if different, the result is negative.

2. **Exponent Calculation**:
    - The exponent bits from both numbers are added.
    - The bias component (`8'd127` for bfloat16) is subtracted to get the effective exponent. This adjustment is essential as floating-point numbers use a biased representation for the exponent.

3. **Mantissa Multiplication**:
    - The mantissas of the two input numbers are multiplied. A hidden bit (value = 1) is implicitly assumed to the left of the mantissa in the standard floating-point representation.
    - The result of this multiplication can either be in the range [1, 4) or [0, 1). If it's in the former range, a 1-bit right shift is needed, and the exponent is incremented by 1.

4. **Result Combination**:
    - Depending on the MSB of the mantissa multiplication result, necessary adjustments are made to the exponent, and the final result is formed.

---

### bfloat16_div

#### Overview
The `bfloat16_div` module performs a division operation on two bfloat16 format numbers. The bfloat16 format is a 16-bit wide floating-point format consisting of 1 sign bit, 8 exponent bits, and 7 mantissa bits.

#### Parameters
- `WIDTH`: The width of the input and output numbers. The default value is 16 for bfloat16.

#### Ports
**Inputs**:

- `a`: A `WIDTH`-bit wide input representing the dividend in bfloat16 format.
- `b`: A `WIDTH`-bit wide input representing the divisor in bfloat16 format.

**Outputs**:

- `result`: A `WIDTH`-bit wide output representing the division result of `a` by `b` in bfloat16 format.

#### Detailed Description
1. **Sign Bit Calculation**:
    - The sign bit of the result is computed using the XOR of the sign bits of the dividend (`a`) and the divisor (`b`). This is based on the floating-point division property: If the signs of the two numbers are the same, the result is positive; if different, the result is negative.

2. **Exponent Calculation**:
    - The divisor's exponent is subtracted from the exponent of the dividend to get the effective exponent of the result. This represents the magnitude of the difference between two exponents.
    - This difference is computed without considering the bias, as the bias components would cancel each other out.

3. **Mantissa Division**:
    - The mantissas of the dividend and divisor are divided. A hidden bit (value = 1) is implicitly assumed to the left of the mantissa in the standard floating-point representation.
    - The result of this division can either have a leading 1 or a leading 0. Depending on this, normalization may be needed.

4. **Result Combination**:
    - Depending on the MSB of the mantissa division result, necessary adjustments are made to the exponent, and the final result is assembled.

---

### vector_regs

#### Overview

The `vector_regs` module is a storage element designed to manage multiple data vectors. A series of registers represent each vector. The module allows for both partial and full writes to these vectors and reading data from a selected vector.

#### Parameters

- `WIDTH`: The bit-width of each element within a vector. The default is 16 bits.
- `NUM_VECTORS`: Number of vectors managed by the module. The default value is 4.
- `VECTOR_SIZE`: The number of elements in each vector. The default value is 16.

#### Ports
**Inputs**:

- `clk`: Clock input signal.
- `rst`: Reset signal.
- `read_addr`: A 2-bit address to select which vector to read from.
- `we`: Write enable signal for partial write.
- `write_addr`: A 6-bit address where [5:4] selects the register (or vector) and [3:0] selects the element within the vector.
- `write_data`: Data for the partial write. It has a width of `WIDTH`.
- `full_we`: Full write enable signal.
- `full_write_data`: 256-bit input representing data to be written to an entire vector.

**Outputs**:

- `read_data`: Output data from the selected vector. It is `WIDTH` times `VECTOR_SIZE` bits wide, representing a full vector.

#### Detailed Description

1. **Storage**:
    - The module consists of an array named `registers` which holds the data for `NUM_VECTORS` vectors. Each vector can hold `VECTOR_SIZE` elements, each being `WIDTH` bits wide.

2. **Partial Write**:
    - Enabled by the `we` signal. 
    - The address is specified by `write_addr`. The top 2 bits of `write_addr` ([5:4]) select the vector, while the lower 4 bits ([3:0]) select the element within the vector.
    - The selected element within the specified vector is updated with `write_data`.

3. **Full Write**:
    - Enabled by the `full_we` signal.
    - The top 2 bits of `write_addr` select which vector to write to.
    - The entire vector specified by the top 2 bits of `write_addr` is updated with `full_write_data`.

4. **Read Operation**:
    - The vector to be read is specified by `read_addr`.
    - The full data from the selected vector is driven to the `read_data` output.

The `vector_regs` module offers flexibility in data management by providing both granular and bulk data write operations, combined with straightforward read capabilities.

---

### scalar_regs

#### Overview

The `scalar_regs` module is a storage element designed to manage multiple scalar values. Each scalar value is stored in a separate register within the module. The module provides mechanisms to write to and read from these scalar registers.

#### Parameters

- `WIDTH`: The bit-width of each scalar register. The default value is 16 bits.
- `NUM_SCALARS`: Number of scalar registers managed by the module. The default value is 4.

#### Ports
**Inputs**:

- `clk`: Clock input signal.
- `rst`: Reset signal.
- `read_addr`: A 2-bit address used to select which scalar register to read from.
- `we`: Write enable signal.
- `write_addr`: A 4-bit address used to select which scalar register to write to.
- `write_data`: Data input for the write operation. It has a width of `WIDTH`.

**Outputs**:

- `read_data`: Output data from the selected scalar register. It has a width of `WIDTH`.

#### Detailed Description

1. **Storage**:
    - The module contains an array named `registers` which holds the data for `NUM_SCALARS` scalar registers. Each scalar register is `WIDTH` bits wide.

2. **Write Operation**:
    - Enabled by the `we` signal.
    - The scalar register to write to is specified by `write_addr`.
    - The specified scalar register is updated with the value from `write_data`.

3. **Read Operation**:
    - The scalar register to read from is specified by `read_addr`.
    - The data from the selected scalar register is driven to the `read_data` output.

The `scalar_regs` module offers a compact way to manage multiple scalar values, providing easy write and read capabilities for data storage and retrieval.
