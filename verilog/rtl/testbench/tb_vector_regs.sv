`timescale 1ns / 1ps

module tb_vector_regs;

    // Parameters
    parameter WIDTH = 16;

    // Signals
    reg clk = 0;
    reg [1:0] tb_read_addr;
    wire [255:0] tb_read_data;
    reg tb_we;
    reg [5:0] tb_write_addr;
    reg [WIDTH-1:0] tb_write_data;
    reg tb_full_we;
    reg [255:0] tb_full_write_data;
    wire [255:0] tb_registerout_0;
    wire [255:0] tb_registerout_1;
    wire [255:0] tb_registerout_2;
    wire [255:0] tb_registerout_3;

    // Instantiate the DUT
    vector_regs #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .read_addr(tb_read_addr),
        .read_data(tb_read_data),
        .we(tb_we),
        .write_addr(tb_write_addr),
        .write_data(tb_write_data),
        .full_we(tb_full_we),
        .full_write_data(tb_full_write_data),
        .registerout_0(tb_registerout_0),
        .registerout_1(tb_registerout_1),
        .registerout_2(tb_registerout_2),
        .registerout_3(tb_registerout_3)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    // Testbench sequence
    initial begin
        tb_we = 0;
        tb_full_we = 0;

        // Full write to the registers
        tb_full_we = 1;
        tb_write_addr = 6'b000000;
        tb_full_write_data = 256'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0;
        #10;

        tb_full_we = 0;

        // Read back the values and display
        tb_read_addr = 2'b00;
        #10 $display("Read Addr: %0b Read Data: %h Register Out 0: %h", tb_read_addr, tb_read_data, tb_registerout_0);

        // Partial write to the registers
        tb_we = 1;
        tb_write_addr = 6'b000001; // Writing to register 0, element 1
        tb_write_data = 16'hF00D;
        #10;

        tb_we = 0;

        // Read back the values and display
        tb_read_addr = 2'b00;
        #10 $display("Read Addr: %0b Read Data: %h Register Out 0: %h", tb_read_addr, tb_read_data, tb_registerout_0);

        $finish; // End the simulation
    end

endmodule