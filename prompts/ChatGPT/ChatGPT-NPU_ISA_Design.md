# NPU ISA Design

#### You:
We will design an NPU that accelerates common machine learning operations. The NPU will receive commands from a RISC-V cpu via a wishbone bus, this wishbone bus mainly has 2 32-bit signals one for the address and one for the instruction/data. We will use bf16 as the native data format. We will use 16 processing elements to execute operations in parallel. We will have 16 vector registers each containing 16 bf16 values. We will have 16 scalar registers each containing 1 bf16 value. We will support 4x4 matrix multiplication as one of the operations, for this operation source vector registers will contain all 16 values of the 4x4 matrix.

We will use address 0x30000000 for receiving instructions using the instruction/data signal, other addresses starting from 0x30000001 will be used to read/write 16bit portions of the registers. Addresses 0x30000001 to 0x30000010 will be scalar registers. Addresses 0x30000011 to 0x30000110 will be 16 bit portions of the vector registers starting from vector register 0.

Which low level operations should our processing elements support?

#### ChatGPT:
Designing a Neural Processing Unit (NPU) that accelerates common machine learning operations is an ambitious project. Since you're aiming to integrate this NPU with a RISC-V CPU via a Wishbone bus and have specific register configurations, you're already well into the specifics.

Given your specific needs, here's a list of low-level operations that your processing elements could support to make the NPU versatile for machine learning tasks:

### Arithmetic Operations:

1. **BF16\_ADD**: Addition of two bf16 numbers.
2. **BF16\_SUB**: Subtraction of two bf16 numbers.
3. **BF16\_MUL**: Multiplication of two bf16 numbers.
4. **BF16\_DIV**: Division of two bf16 numbers.

### Vector Operations:

1. **VEC\_ADD**: Element-wise addition of two vectors.
2. **VEC\_SUB**: Element-wise subtraction of two vectors.
3. **VEC\_MUL**: Element-wise multiplication of two vectors.
4. **VEC\_DIV**: Element-wise division of two vectors.
5. **VEC\_DOT**: Dot product of two vectors.

### Matrix Operations:

1. **MATMUL\_4x4**: Matrix multiplication for 4x4 matrices stored in vector registers.
2. **MATVEC\_MUL**: Matrix-vector multiplication.

### Activation Functions:

1. **ACT\_RELU**: Rectified Linear Unit (ReLU) activation.
2. **ACT\_SIGMOID**: Sigmoid activation.
3. **ACT\_TANH**: Hyperbolic Tangent (tanh) activation.

### Data Movement:

1. **LOAD\_VEC**: Load data into a vector register.
2. **STORE\_VEC**: Store data from a vector register.
3. **LOAD\_SCALAR**: Load data into a scalar register.
4. **STORE\_SCALAR**: Store data from a scalar register.

### Reductions:

1. **VEC\_SUM**: Sum of all elements in a vector.
2. **VEC\_MAX**: Maximum element in a vector.
3. **VEC\_MIN**: Minimum element in a vector.

### Miscellaneous:

1. **NOP**: No operation.
2. **SET\_ZERO**: Set register to zero.
3. **COPY**: Copy data from one register to another.

### Logical Operations:

1. **AND**: Bitwise AND
2. **OR**: Bitwise OR
3. **XOR**: Bitwise XOR

This list can be expanded depending on the specific machine learning workloads you're targeting. Also, you could have more specialized instructions for things like convolutions if you want the NPU to efficiently handle CNNs, or sequence operations if RNNs are a target.

You will also need to design the control logic to manage these operations, including instruction fetch, decode, and execution stages. Depending on how complex you want to make the NPU, you might also add pipelining, out-of-order execution, or even specialized memory hierarchies.


#### You:
Now according to these low level operations design a complete ISA, show the ISA as a table. Make addresses 4 bits wide. Do not include load/store, sigmoid, tanh and Arithmetic Operations. No immediate values.

#### ChatGPT:
Designing a complete ISA (Instruction Set Architecture) includes specifying the opcode, operation, and operands for each instruction. Since you've specified that addresses are 4 bits wide, you'll be limited in how you can specify operands. Given that restriction, you may want to have a very compact encoding.

Here's a simple example of what part of your ISA could look like. Note that this is a basic example and a real ISA would need to be much more detailed and carefully thought out.

| Opcode (4 bits) | Operation   | Description                            | Operand 1 (4 bits)   | Operand 2 (4 bits) | Operand 3 (4 bits)   |
| --------------- | ----------- | -------------------------------------- | -------------------- | ------------------ | -------------------- |
| 0001            | VEC\_ADD    | Vector addition                        | Vector Register 1    | Vector Register 2  | Destination Register |
| 0010            | VEC\_SUB    | Vector subtraction                     | Vector Register 1    | Vector Register 2  | Destination Register |
| 0011            | VEC\_MUL    | Element-wise vector multiplication     | Vector Register 1    | Vector Register 2  | Destination Register |
| 0100            | VEC\_DIV    | Element-wise vector division           | Vector Register 1    | Vector Register 2  | Destination Register |
| 0101            | VEC\_DOT    | Dot product of two vectors             | Vector Register 1    | Vector Register 2  | Destination Register |
| 0110            | MATMUL\_4x4 | 4x4 matrix multiplication              | Matrix 1 Register    | Matrix 2 Register  | Destination Register |
| 0111            | MATVEC\_MUL | Matrix-vector multiplication           | Matrix Register      | Vector Register    | Destination Register |
| 1000            | ACT\_RELU   | ReLU activation                        | Source Register      | N/A                | Destination Register |
| 1001            | VEC\_SUM    | Sum of all elements in a vector        | Vector Register      | N/A                | Destination Register |
| 1010            | VEC\_MAX    | Maximum element in a vector            | Vector Register      | N/A                | Destination Register |
| 1011            | VEC\_MIN    | Minimum element in a vector            | Vector Register      | N/A                | Destination Register |
| 1100            | NOP         | No operation                           | N/A                  | N/A                | N/A                  |
| 1101            | SET\_ZERO   | Set register to zero                   | Destination Register | N/A                | N/A                  |
| 1110            | COPY        | Copy data from one register to another | Source Register      | N/A                | Destination Register |
| 1111            | AND         | Bitwise AND                            | Register 1           | Register 2         | Destination Register |
| ...             | ...         | ...                                    | ...                  | ...                | ...                  |

You'll notice that the table only includes the instructions you asked for (omitting load/store, sigmoid, tanh, and arithmetic operations), and does not use immediate values. Additionally, for the `MATMUL_4x4` operation, the operand registers would actually need to contain pointers to the start of 4x4 matrices in register files or memory, since a single 4-bit register cannot hold an entire matrix.

This table should be expanded and adapted based on the specifics of your design. Also, remember that this is a simplified example and does not include all the details you'll need for a complete design, such as control signals, status flags, or exception handling.


#### You:
Remove set_zero, copy, and. Add xor, or, and. Move NOP to top of the list. Adjust opcodes accordingly. Write destination scalar register or destination vector register instead of destination register to places necessary.

#### ChatGPT:
Sure, here's the revised ISA table:

| Opcode (4 bits) | Operation   | Description                        | Operand 1 (4 bits) | Operand 2 (4 bits) | Operand 3 (4 bits)          |
| --------------- | ----------- | ---------------------------------- | ------------------ | ------------------ | --------------------------- |
| 0000            | NOP         | No operation                       | N/A                | N/A                | N/A                         |
| 0001            | VEC\_ADD    | Vector addition                    | Vector Register 1  | Vector Register 2  | Destination Vector Register |
| 0010            | VEC\_SUB    | Vector subtraction                 | Vector Register 1  | Vector Register 2  | Destination Vector Register |
| 0011            | VEC\_MUL    | Element-wise vector multiplication | Vector Register 1  | Vector Register 2  | Destination Vector Register |
| 0100            | VEC\_DIV    | Element-wise vector division       | Vector Register 1  | Vector Register 2  | Destination Vector Register |
| 0101            | VEC\_DOT    | Dot product of two vectors         | Vector Register 1  | Vector Register 2  | Destination Scalar Register |
| 0110            | MATMUL\_4x4 | 4x4 matrix multiplication          | Matrix 1 Register  | Matrix 2 Register  | Destination Vector Register |
| 0111            | MATVEC\_MUL | Matrix-vector multiplication       | Matrix Register    | Vector Register    | Destination Vector Register |
| 1000            | ACT\_RELU   | ReLU activation                    | Source Register    | N/A                | Destination Vector Register |
| 1001            | VEC\_SUM    | Sum of all elements in a vector    | Vector Register    | N/A                | Destination Scalar Register |
| 1010            | VEC\_MAX    | Maximum element in a vector        | Vector Register    | N/A                | Destination Scalar Register |
| 1011            | VEC\_MIN    | Minimum element in a vector        | Vector Register    | N/A                | Destination Scalar Register |
| 1100            | OR          | Bitwise OR                         | Register 1         | Register 2         | Destination Register        |
| 1101            | XOR         | Bitwise XOR                        | Register 1         | Register 2         | Destination Register        |
| 1110            | AND         | Bitwise AND                        | Register 1         | Register 2         | Destination Register        |

Note that I've made some assumptions in this table that you'll need to verify or modify according to your design. For example, I've assumed that `ACT_RELU` will operate on an entire vector, and that the result of `VEC_DOT` will be a scalar. Your design may handle these operations differently. Also, I've listed `OR`, `XOR`, and `AND` as operating on generic registers, but you'll need to specify whether they operate on scalar or vector registers, and adjust the Opcode and Operands accordingly.


#### You:
Since our instructions are 16 bits long can we get 2 instructions at a time using our wishbone bus?

#### ChatGPT:
The Wishbone bus you mentioned in your initial question has 32-bit signals for address and instruction/data. If your instructions are 16 bits long, then technically, yes, you could transfer two instructions at a time over a 32-bit bus.

However, there are several things you need to consider:

1. **Alignment**: If your instructions are 16 bits, you will need to decide how they are aligned when two of them are packed into a 32-bit bus word. Is the first instruction in the most significant bits or the least significant bits? This will affect how you unpack the instructions at the receiving end.

2. **Instruction Decoding**: Your instruction decoder will need to be designed to handle this. It will need to extract the two instructions from the 32-bit word and decode them separately.

3. **Execution**: Depending on your design, you may be able to execute both instructions simultaneously (if your NPU supports dual-issue or more complex forms of instruction-level parallelism), or you may need to execute them sequentially.

4. **Hazard Detection**: You will need to have logic in place to detect any hazards between the two instructions. For example, if the first instruction writes to a register that the second instruction reads, you have a data hazard and must handle it appropriately.

5. **Control Signals**: The Wishbone bus protocol includes control signals (e.g. strobe, acknowledge, etc.) that will need to be managed appropriately if you are sending two instructions at once.

6. **Compatibility**: You will need to ensure that this approach is compatible with the rest of your system, including the RISC-V CPU and any other components connected to the Wishbone bus.

In summary, it is possible to send two 16-bit instructions at a time over a 32-bit Wishbone bus, but it will require careful design and may introduce complexity in your instruction decoding, execution, and hazard detection logic.


#### You:
Now we will write the control unit starting from regular vector oprations. For the control unit, for opcodes 0001, 0010, 0011, 0100 (regular vector operations) we will pass the first 16 bytes of the vector registers to the first PE, second 16 bytes to the second PE and so on until 16th PE.

Control module will output signals for the memory access, writeback and register file modules to control them. Start implementing this SystemVerilog module.

#### ChatGPT:
To implement the control unit in SystemVerilog, you'll need to define the module, its inputs, outputs, and internal signals, and then describe the logic that controls the signals based on the current state and inputs.

Below is a skeleton of a SystemVerilog module for the control unit of your NPU. Note that this is a simplified version and you will need to expand and modify it to fit your complete design.

```systemverilog
module control_unit (
    input logic [3:0] opcode, // 4-bit opcode
    input logic clock, // clock signal
    input logic reset, // reset signal
    output logic mem_access, // memory access signal
    output logic writeback, // writeback signal
    output logic [3:0] reg_file // register file signals
    );

    // define internal signals
    logic [15:0] vector_reg_file [15:0]; // vector register file
    logic [3:0] pe_signals [15:0]; // signals to the processing elements

    // always block triggered on the positive edge of the clock
    always_ff @(posedge clock or posedge reset)
    begin
        if (reset)
        begin
            // reset all signals
            mem_access <= 0;
            writeback <= 0;
            reg_file <= 4'b0000;
            pe_signals <= '{default:4'b0000};
        end
        else
        begin
            case (opcode)
                4'b0001, 4'b0010, 4'b0011, 4'b0100: // regular vector operations
                begin
                    // set signals for memory access, writeback, and register file
                    mem_access <= 1;
                    writeback <= 1;
                    reg_file <= opcode;

                    // set
```
