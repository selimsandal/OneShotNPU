`timescale 1ns / 1ps

module tb_bfloat16_addsub;

    // Parameter
    parameter WIDTH = 16;

    // Signals
    logic [WIDTH-1:0] a, b;
    logic [WIDTH-1:0] result;
    logic is_sub;

    // Instantiate the DUT
    bfloat16_addsub #(WIDTH) uut (
        .a(a),
        .b(b),
        .result(result),
        .is_sub(is_sub)
    );

    // Test sequence
    initial begin
        // Test cases for addition
        is_sub = 0;
        a = 16'h4040; // 3.0 in bfloat16
        b = 16'h4080; // 4.0 in bfloat16
        #10;
        $display("Addition: a = %h, b = %h, result = %h", a, b, result);

        a = 16'h4000; // 2.0 in bfloat16
        b = 16'h4040; // 3.0 in bfloat16
        #10;
        $display("Addition: a = %h, b = %h, result = %h", a, b, result);

        // Test cases for subtraction
        is_sub = 1;
        a = 16'h4080; // 4.0 in bfloat16
        b = 16'h4040; // 3.0 in bfloat16
        #10;
        $display("Subtraction: a = %h, b = %h, result = %h", a, b, result);

        a = 16'h4040; // 3.0 in bfloat16
        b = 16'h4000; // 2.0 in bfloat16
        #10;
        $display("Subtraction: a = %h, b = %h, result = %h", a, b, result);

        // Additional test cases can be added

        // Finish simulation
        #100 $finish;
    end

endmodule