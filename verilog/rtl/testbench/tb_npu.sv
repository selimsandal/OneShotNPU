`timescale 1ns / 1ps

module tb_npu;

    // Parameters
    parameter WIDTH = 16;
    parameter NUM_VECTORS = 4;
    parameter VECTOR_SIZE = 16;
    parameter NUM_SCALARS = 4;

    // Clock and reset signals
    reg wb_clk_i = 0;
    reg wb_rst_i = 1'b0;
    reg wbs_stb_i = 0;
    reg wbs_cyc_i = 0;
    reg wbs_we_i = 0;
    reg [31:0] wbs_dat_i = 0;

    wire wbs_ack_o;
    wire [31:0] wbs_dat_o;

    // Instantiate the NPU
    npu dut (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)
    );

    // Clock generation
    always begin
        #5 wb_clk_i = ~wb_clk_i;
    end

    // Testbench stimulus
    initial begin
        // Reset pulse
        wb_rst_i = 1'b1;
        #10 wb_rst_i = 1'b0;

        // Some generic stimulus (Modify as per your design needs)
        wbs_stb_i = 1;
        wbs_cyc_i = 1;
        wbs_dat_i = 32'h12345678;
        #20;

        wbs_we_i = 1;
        #10;
        wbs_we_i = 0;
        wbs_dat_i = 32'h87654321;
        #20;

        // Add more stimulus as required...

        $finish;
    end

    // Monitor the output
    always @(posedge wb_clk_i) begin
        if(wbs_ack_o) begin
            $display("Data Acknowledged: %h", wbs_dat_o);
        end
    end

endmodule