module bfloat16_addsub #(
    parameter WIDTH = 16
) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] result,
    input is_sub
);
    
    // Extracting the sign of the result from the two sign bits.
    assign result[WIDTH-1] = a[WIDTH-1] ^ (is_sub & b[WIDTH-1]);
    
    // Subtracting the exponents E_a and E_b and finding the absolute value of the exponent difference (E)
    logic [7:0] E;
    assign E = (a[WIDTH-2 : WIDTH-8] > b[WIDTH-2 : WIDTH-8]) ? a[WIDTH-2 : WIDTH-8] - b[WIDTH-2 : WIDTH-8] : b[WIDTH-2 : WIDTH-8] - a[WIDTH-2 : WIDTH-8];
    
    // Shifting the mantissa of the lesser number by E bits considering the hidden bits.
    logic [7:0] M_a, M_b;
    assign M_a = {1'b1, a[WIDTH-3 : WIDTH-9]};
    assign M_b = {1'b1, b[WIDTH-3 : WIDTH-9]};
    
    logic [7:0] shifted_M_a, shifted_M_b;
    always_comb begin
        if (a[WIDTH-2 : WIDTH-8] > b[WIDTH-2 : WIDTH-8]) begin
            shifted_M_a = M_a >> E;
            shifted_M_b = M_b << E;
        end else begin
            shifted_M_a = M_a << E;
            shifted_M_b = M_b >> E;
        end
    end
    
    // Executing addition or subtraction operation between the shifted version of the mantissa and the mantissa of the other number.
    logic [7:0] M_res;
    assign M_res = is_sub ? shifted_M_a - shifted_M_b : shifted_M_a + shifted_M_b;
    
    // Normalization for addition and subtraction
    always_comb begin
        if (is_sub) begin
            if (M_res[7] == 1'b0) begin
                result[WIDTH-2 : WIDTH-9] = a[WIDTH-2 : WIDTH-9] + E;
                result[WIDTH-10 : 0] = M_res[6:0];
            end else begin
                result[WIDTH-2 : WIDTH-9] = a[WIDTH-2 : WIDTH-9] + E - 1'b1;
                result[WIDTH-9 : 0] = {M_res[6:0], 1'b1};
            end
        end else begin
            if (M_res[7] == 1'b0) begin
                result[WIDTH-2 : WIDTH-9] = a[WIDTH-2 : WIDTH-9];
                result[WIDTH-10 : 0] = M_res[6:0];
            end else begin
                result[WIDTH-2 : WIDTH-9] = a[WIDTH-2 : WIDTH-9] + 1'b1;
                result[WIDTH-9 : 0] = {M_res[6:0], 1'b1};
            end
        end
    end
endmodule

module bfloat16_mul #(
    parameter WIDTH = 16
) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] result
);
    
    // Extracting the sign of the result from the two sign bits.
    assign result[WIDTH-1] = a[WIDTH-1] ^ b[WIDTH-1];
    
    // Adding the exponents (E) and subtracting the bias component.
    logic [7:0] E;
    assign E = a[WIDTH-2 : WIDTH-8] + b[WIDTH-2 : WIDTH-8] - 8'd127;
    
    // Multiplying mantissa of b (M_b) by mantissa of a (M_a) considering the hidden bits.
    logic [15:0] M_res;
    assign M_res = {1'b0, a[WIDTH-3 : WIDTH-9]} * {1'b0, b[WIDTH-3 : WIDTH-9]};
    
    // If the MSB of the product is \lq 1\rq then shift the result to the right by 1-bit.
    always_comb begin
        if (M_res[15] == 1'b0) begin
            result[WIDTH-2 : WIDTH-9] = E;
            result[WIDTH-9 : 0] = M_res[14:7];
        end else begin
            result[WIDTH-2 : WIDTH-9] = E + 1'b1;
            result[WIDTH-9 : 0] = {M_res[14:8], 1'b1};
        end
    end
endmodule

module bfloat16_div #(
    parameter WIDTH = 16
) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] result
);
    
    // Extracting the sign of the result from the two sign bits.
    assign result[WIDTH-1] = a[WIDTH-1] ^ b[WIDTH-1];
    
    // Finding the magnitude of the difference between two exponents (E) and adding or subtracting bias according to E_b > E_a or E_b < E_a.
    logic [7:0] E;
    assign E = a[WIDTH-2 : WIDTH-8] - b[WIDTH-2 : WIDTH-8];
    
    // Dividing mantissa of  b (M_b) by mantissa of  a (M_a) considering the hidden bits.
    logic [15:0] M_res;
    assign M_res = {1'b0, b[WIDTH-3 : WIDTH-9]} / {1'b0, a[WIDTH-3 : WIDTH-9]};
    
    // If there is a leading zero then normalize the result by shifting it left.
    always_comb begin
        if (M_res[15] == 1'b0) begin
            result[WIDTH-2 : WIDTH-9] = E;
            result[WIDTH-9 : 0] = {1'b0, M_res[14:8]};
        end else begin
            result[WIDTH-2 : WIDTH-9] = E - 1'b1;
            result[WIDTH-9 : 0] = {M_res[14:8], 1'b1};
        end
    end
endmodule

module vector_regs #(
    parameter WIDTH = 16
) (
    input logic clk,
    
    input [1:0] read_addr,
    output logic [255:0] read_data, //partial read
    input we, //write enable,
    input [5:0] write_addr, // [5:4] selects register, [3:0] selects element
    input [WIDTH-1:0] write_data, //partial write
    input full_we, //full write enable
    input [255:0] full_write_data,
    output logic [255:0] registerout_0,
    output logic [255:0] registerout_1,
    output logic [255:0] registerout_2,
    output logic [255:0] registerout_3
);

    
    
    logic [255:0] register_0;
    logic [255:0] register_1;
    logic [255:0] register_2;
    logic [255:0] register_3;

    assign registerout_0 = register_0;
    assign registerout_1 = register_1;
    assign registerout_2 = register_2;
    assign registerout_3 = register_3;

    always_ff @(posedge clk) begin
        if (we) begin
            case (write_addr[5:4])
                2'b00: register_0[write_addr[3:0]*WIDTH +: WIDTH] <= write_data;
                2'b01: register_1[write_addr[3:0]*WIDTH +: WIDTH] <= write_data;
                2'b10: register_2[write_addr[3:0]*WIDTH +: WIDTH] <= write_data;
                2'b11: register_3[write_addr[3:0]*WIDTH +: WIDTH] <= write_data;
            endcase
        end

        if (full_we) begin
            case (write_addr[5:4])
                2'b00: register_0 <= full_write_data;
                2'b01: register_1 <= full_write_data;
                2'b10: register_2 <= full_write_data;
                2'b11: register_3 <= full_write_data;
            endcase
        end
    end

    always_comb begin
        case (read_addr)
            2'b00: read_data = register_0;
            2'b01: read_data = register_1;
            2'b10: read_data = register_2;
            2'b11: read_data = register_3;
            default: read_data = 256'b0;
        endcase
    end

endmodule


module scalar_regs #(
    parameter WIDTH = 16,
    parameter NUM_SCALARS = 4
) (
    input logic clk,
    
    input [1:0] read_addr,
    output logic [WIDTH-1:0] read_data,
    input we, //write enable
    input [3:0] write_addr, // selects register
    input [WIDTH-1:0] write_data,
    output logic [WIDTH-1:0] registers_out[NUM_SCALARS]
);
    
    
    logic [WIDTH-1:0] registers[NUM_SCALARS];

    assign registers_out = registers;
    
    always_ff @(posedge clk) begin
        if (we) begin
            registers[write_addr] <= write_data;
        end
    end
    
    assign read_data = registers[read_addr];
endmodule

module processing_element #(
    parameter WIDTH = 16
) (
    input [3:0] opcode,
    input [WIDTH-1:0] a_in,
    input [WIDTH-1:0] b_in,
    output logic [WIDTH-1:0] result
);

    // Outputs for each operation
    logic [WIDTH-1:0] add_result;
    logic [WIDTH-1:0] sub_result;
    logic [WIDTH-1:0] mul_result;
    logic [WIDTH-1:0] div_result;
    
    // Instantiate bfloat modules
    bfloat16_addsub #(WIDTH) addsub_instance(.a(a_in), .b(b_in), .result(add_result), .is_sub(1'b0)); // add
    bfloat16_addsub #(WIDTH) sub_instance (.a(a_in), .b(b_in), .result(sub_result), .is_sub(1'b1)); // subtract
    bfloat16_mul #(WIDTH) mul_instance(.a(a_in), .b(b_in), .result(mul_result)); // multiply
    bfloat16_div #(WIDTH) div_instance(.a(a_in), .b(b_in), .result(div_result)); // divide

    // Select the result based on the opcode
    always_comb begin
        case (opcode)
            4'b0001, 4'b0010: result = add_result;
            4'b0011, 4'b0100: result = sub_result;
            4'b0101, 4'b0110: result = mul_result;
            4'b0111, 4'b1000: result = div_result;
            default: result = 0; // Handle unknown opcodes
        endcase
    end

endmodule


module instruction_decoder (
    input [31:0] inst,
    output logic [3:0] opcode,
    output logic [5:0] src1, //only first 2 bits used outside of load/store operations
    output logic [5:0] src2, //only first 2 bits used outside of load/store operations
    output logic [1:0] dest,
    output logic [15:0] immediate
);
    
    assign opcode = inst[31:28];
    assign src1 = inst[27:22];
    assign src2 = inst[21:16];
    assign dest = inst[15:14];
    assign immediate = inst[15:0];
endmodule

module npu #(
    parameter WIDTH = 16,
    parameter NUM_VECTORS = 4,
    parameter VECTOR_SIZE = 16,
    parameter NUM_SCALARS = 4
) (
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [31:0] wbs_dat_i,
    output logic wbs_ack_o,
    output logic [31:0] wbs_dat_o
);

logic [255:0] register_0;
logic [255:0] register_1;
logic [255:0] register_2;
logic [255:0] register_3;

logic [WIDTH-1:0] scalar_registers[NUM_SCALARS];

    logic [3:0] opcode;
    logic [5:0] src1, src2, dest;
    logic [15:0] immediate;
    logic [255:0] vector_read_data;
    logic [15:0] scalar_read_data;

    instruction_decoder decoder(.inst(wbs_dat_i), .opcode(opcode), .src1(src1), .src2(src2), .dest(dest[5:4]), .immediate(immediate));

    logic [1:0] vec_read_addr;
    logic vec_we;
    logic [5:0] vec_write_addr;
    logic [15:0] vec_write_data;
    logic vec_full_we;
    logic [255:0] vec_full_write_data;

    vector_regs vectors(.clk(wb_clk_i), .read_addr(vec_read_addr), .read_data(vector_read_data), .we(vec_we), .write_addr(vec_write_addr), .write_data(vec_write_data), .full_we(vec_full_we), .full_write_data(vec_full_write_data), .registerout_0(register_0), .registerout_1(register_1), .registerout_2(register_2), .registerout_3(register_3));
    
    logic [1:0] scalar_read_addr;
    logic [WIDTH-1:0] scalar_write_data;
    logic scalar_we;
    scalar_regs #(WIDTH, NUM_SCALARS) scalars(.clk(wb_clk_i), 
                                      .read_addr(scalar_read_addr), .read_data(scalar_read_data), .we(scalar_we), .write_addr(src2[5:2]), .write_data(scalar_write_data), .registers_out(scalar_registers));
    
    // Processing elements
    logic [WIDTH-1:0] a_in[VECTOR_SIZE];
    logic [WIDTH-1:0] b_in[VECTOR_SIZE];
    logic [WIDTH-1:0] result[VECTOR_SIZE];

    genvar i;
    generate
        for (i = 0; i < VECTOR_SIZE; i++) begin : pe_gen
            processing_element #(WIDTH) pe(.opcode(opcode), .a_in(a_in[i]), .b_in(b_in[i]), .result(result[i]));
        end
    endgenerate

    // Concat results and write back to vector register
    logic [WIDTH*VECTOR_SIZE-1:0] result_concat;
    always_comb begin
        for (int i = 0; i < VECTOR_SIZE; i++) begin
            result_concat[i*WIDTH +: WIDTH] = result[i];
        end
    end

    always_ff @(posedge wb_clk_i) begin
        if (wbs_stb_i && wbs_cyc_i) begin
            case (opcode)
                4'b0001: begin //vector-vector add
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
            
                        case (src2)
                            2'b00: b_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: b_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: b_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: b_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
                4'b0010: begin //vector-scalar add
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                        b_in[i] <= scalar_read_data;
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end

                4'b0011: begin //vector-vector subtract
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
            
                        case (src2)
                            2'b00: b_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: b_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: b_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: b_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
                4'b0100: begin //vector-scalar subtract
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                        b_in[i] <= scalar_read_data;
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
            
                4'b0101: begin //vector-vector multiply
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
            
                        case (src2)
                            2'b00: b_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: b_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: b_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: b_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
            
                4'b0110: begin //vector-scalar multiply
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                        b_in[i] <= scalar_read_data;
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
            
                4'b0111: begin //vector-vector divide
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
            
                        case (src2)
                            2'b00: b_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: b_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: b_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: b_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end
            
            
                4'b1000: begin //vector-scalar divide
                    for (int i = 0; i < VECTOR_SIZE; i++) begin
                        case (src1)
                            2'b00: a_in[i] <= register_0[i*WIDTH +: WIDTH];
                            2'b01: a_in[i] <= register_1[i*WIDTH +: WIDTH];
                            2'b10: a_in[i] <= register_2[i*WIDTH +: WIDTH];
                            2'b11: a_in[i] <= register_3[i*WIDTH +: WIDTH];
                        endcase
                        b_in[i] <= scalar_read_data;
                    end
                    vec_write_addr <= dest;
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b1;
                    vec_full_write_data <= result_concat;
                end

                4'b1001: begin //load vector element
                    vec_read_addr <= src2[5:4];
                    vec_write_addr <= dest;
                    vec_we <= 1'b1;
                    vec_full_we <= 1'b0;
                    vec_write_data <= immediate;
                end
            
                4'b1010: begin //read vector element
                    case (src2)
                        2'b00: wbs_dat_o[15:0] <= register_0[immediate*WIDTH +: WIDTH];
                        2'b01: wbs_dat_o[15:0] <= register_1[immediate*WIDTH +: WIDTH];
                        2'b10: wbs_dat_o[15:0] <= register_2[immediate*WIDTH +: WIDTH];
                        2'b11: wbs_dat_o[15:0] <= register_3[immediate*WIDTH +: WIDTH];
                    endcase
                end
            
                4'b1011: begin //load scalar
                    scalar_we <= 1'b1;
                    scalar_write_data <= immediate;
                end
            
                4'b1100: begin //read scalar
                    wbs_dat_o[15:0] <= scalar_registers[src2];
                end
            
                default: begin
                    vec_we <= 1'b0;
                    vec_full_we <= 1'b0;
                    scalar_we <= 1'b0;
                end
            endcase
            
        end else begin
            vec_we <= 1'b0;
            vec_full_we <= 1'b0;
            scalar_we <= 1'b0;
        end
    end

    //Acknowledge signal
    always_ff @(posedge wb_clk_i) begin
        if (wbs_stb_i && wbs_cyc_i) begin
            wbs_ack_o <= 1'b1;
        end else begin
            wbs_ack_o <= 1'b0;
        end
    end
endmodule