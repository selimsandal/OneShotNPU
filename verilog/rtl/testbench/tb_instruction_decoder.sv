`timescale 1ns / 1ps

module tb_instruction_decoder;

    // Signals
    logic [31:0] inst;
    logic [3:0] opcode;
    logic [5:0] src1, src2;
    logic [1:0] dest;
    logic [15:0] immediate;

    // Instantiate the DUT
    instruction_decoder uut (
        .inst(inst),
        .opcode(opcode),
        .src1(src1),
        .src2(src2),
        .dest(dest),
        .immediate(immediate)
    );

    // Test sequence
    initial begin
        inst = 32'h8000_0000;  // Simple test instruction
        #10;
        $display("Instruction: %h", inst);
        $display("Decoded: opcode=%h, src1=%h, src2=%h, dest=%h, immediate=%h", opcode, src1, src2, dest, immediate);

        inst = 32'hA543_21F0;  // Another test instruction
        #10;
        $display("Instruction: %h", inst);
        $display("Decoded: opcode=%h, src1=%h, src2=%h, dest=%h, immediate=%h", opcode, src1, src2, dest, immediate);

        // You can continue adding more test instructions as necessary to test the decoder functionality

        // Finish simulation
        #100 $finish;
    end

endmodule