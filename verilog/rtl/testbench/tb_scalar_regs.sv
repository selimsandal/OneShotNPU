`timescale 1ns / 1ps

module tb_scalar_regs;

    // Parameters
    parameter WIDTH = 16;
    parameter NUM_SCALARS = 4;

    // Signals
    reg clk = 0;
    reg [1:0] tb_read_addr;
    wire [WIDTH-1:0] tb_read_data;
    reg tb_we;
    reg [3:0] tb_write_addr;
    reg [WIDTH-1:0] tb_write_data;
    wire [WIDTH-1:0] tb_registers_out[NUM_SCALARS];

    // Instantiate the DUT
    scalar_regs #(
        .WIDTH(WIDTH),
        .NUM_SCALARS(NUM_SCALARS)
    ) dut (
        .clk(clk),
        .read_addr(tb_read_addr),
        .read_data(tb_read_data),
        .we(tb_we),
        .write_addr(tb_write_addr),
        .write_data(tb_write_data),
        .registers_out(tb_registers_out)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    // Testbench sequence
    initial begin
        tb_we = 0;

        // Write some values to the registers
        tb_we = 1;
        tb_write_addr = 4'b0000;
        tb_write_data = 16'h1234;
        #10;

        tb_write_addr = 4'b0001;
        tb_write_data = 16'h5678;
        #10;

        tb_write_addr = 4'b0010;
        tb_write_data = 16'h9ABC;
        #10;

        tb_write_addr = 4'b0011;
        tb_write_data = 16'hDEF0;
        #10;

        tb_we = 0;

        // Read back the values
        tb_read_addr = 2'b00;
        #10 $display("Read Addr: %0b Read Data: %h Register Out: %h", tb_read_addr, tb_read_data, tb_registers_out[tb_read_addr]);

        tb_read_addr = 2'b01;
        #10 $display("Read Addr: %0b Read Data: %h Register Out: %h", tb_read_addr, tb_read_data, tb_registers_out[tb_read_addr]);

        tb_read_addr = 2'b10;
        #10 $display("Read Addr: %0b Read Data: %h Register Out: %h", tb_read_addr, tb_read_data, tb_registers_out[tb_read_addr]);

        tb_read_addr = 2'b11;
        #10 $display("Read Addr: %0b Read Data: %h Register Out: %h", tb_read_addr, tb_read_data, tb_registers_out[tb_read_addr]);

        $finish; // End the simulation
    end

endmodule