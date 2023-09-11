`timescale 1ns / 1ps

module tb_processing_element;

    // Parameters
    parameter WIDTH = 16;

    // Signals for the DUT (Device Under Test)
    reg [3:0] tb_opcode;
    reg [WIDTH-1:0] tb_a_in;
    reg [WIDTH-1:0] tb_b_in;
    wire [WIDTH-1:0] tb_result;

    // Instantiate the DUT
    processing_element #(
        .WIDTH(WIDTH)
    ) dut (
        .opcode(tb_opcode),
        .a_in(tb_a_in),
        .b_in(tb_b_in),
        .result(tb_result)
    );

    // Clock for our testbench
    initial begin
        // Some sample test values
        tb_a_in = 16'h1234;
        tb_b_in = 16'h5678;

        tb_opcode = 4'b0001; // add
        #10 $display("Opcode: %0b A_in: %h B_in: %h Result: %h", tb_opcode, tb_a_in, tb_b_in, tb_result);

        tb_opcode = 4'b0011; // subtract
        #10 $display("Opcode: %0b A_in: %h B_in: %h Result: %h", tb_opcode, tb_a_in, tb_b_in, tb_result);

        tb_opcode = 4'b0101; // multiply
        #10 $display("Opcode: %0b A_in: %h B_in: %h Result: %h", tb_opcode, tb_a_in, tb_b_in, tb_result);

        tb_opcode = 4'b0111; // divide
        #10 $display("Opcode: %0b A_in: %h B_in: %h Result: %h", tb_opcode, tb_a_in, tb_b_in, tb_result);

        $finish; // End simulation
    end

endmodule