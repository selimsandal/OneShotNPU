module bfloat16_addsub (
	a,
	b,
	result,
	is_sub
);
	parameter WIDTH = 16;
	input wire [WIDTH - 1:0] a;
	input wire [WIDTH - 1:0] b;
	output reg [WIDTH - 1:0] result;
	input is_sub;
	wire [1:1] sv2v_tmp_C1E73;
	assign sv2v_tmp_C1E73 = a[WIDTH - 1] ^ (is_sub & b[WIDTH - 1]);
	always @(*) result[WIDTH - 1] = sv2v_tmp_C1E73;
	wire [7:0] E;
	assign E = (a[WIDTH - 2:WIDTH - 8] > b[WIDTH - 2:WIDTH - 8] ? a[WIDTH - 2:WIDTH - 8] - b[WIDTH - 2:WIDTH - 8] : b[WIDTH - 2:WIDTH - 8] - a[WIDTH - 2:WIDTH - 8]);
	wire [7:0] M_a;
	wire [7:0] M_b;
	assign M_a = {1'b1, a[WIDTH - 3:WIDTH - 9]};
	assign M_b = {1'b1, b[WIDTH - 3:WIDTH - 9]};
	reg [7:0] shifted_M_a;
	reg [7:0] shifted_M_b;
	always @(*)
		if (a[WIDTH - 2:WIDTH - 8] > b[WIDTH - 2:WIDTH - 8]) begin
			shifted_M_a = M_a >> E;
			shifted_M_b = M_b << E;
		end
		else begin
			shifted_M_a = M_a << E;
			shifted_M_b = M_b >> E;
		end
	wire [7:0] M_res;
	assign M_res = (is_sub ? shifted_M_a - shifted_M_b : shifted_M_a + shifted_M_b);
	always @(*)
		if (is_sub) begin
			if (M_res[7] == 1'b0) begin
				result[WIDTH - 2:WIDTH - 9] = a[WIDTH - 2:WIDTH - 9] + E;
				result[WIDTH - 10:0] = M_res[6:0];
			end
			else begin
				result[WIDTH - 2:WIDTH - 9] = (a[WIDTH - 2:WIDTH - 9] + E) - 1'b1;
				result[WIDTH - 9:0] = {M_res[6:0], 1'b1};
			end
		end
		else if (M_res[7] == 1'b0) begin
			result[WIDTH - 2:WIDTH - 9] = a[WIDTH - 2:WIDTH - 9];
			result[WIDTH - 10:0] = M_res[6:0];
		end
		else begin
			result[WIDTH - 2:WIDTH - 9] = a[WIDTH - 2:WIDTH - 9] + 1'b1;
			result[WIDTH - 9:0] = {M_res[6:0], 1'b1};
		end
endmodule
module bfloat16_mul (
	a,
	b,
	result
);
	parameter WIDTH = 16;
	input wire [WIDTH - 1:0] a;
	input wire [WIDTH - 1:0] b;
	output reg [WIDTH - 1:0] result;
	wire [1:1] sv2v_tmp_FB2B6;
	assign sv2v_tmp_FB2B6 = a[WIDTH - 1] ^ b[WIDTH - 1];
	always @(*) result[WIDTH - 1] = sv2v_tmp_FB2B6;
	wire [7:0] E;
	assign E = (a[WIDTH - 2:WIDTH - 8] + b[WIDTH - 2:WIDTH - 8]) - 8'd127;
	wire [15:0] M_res;
	assign M_res = {1'b0, a[WIDTH - 3:WIDTH - 9]} * {1'b0, b[WIDTH - 3:WIDTH - 9]};
	always @(*)
		if (M_res[15] == 1'b0) begin
			result[WIDTH - 2:WIDTH - 9] = E;
			result[WIDTH - 9:0] = M_res[14:7];
		end
		else begin
			result[WIDTH - 2:WIDTH - 9] = E + 1'b1;
			result[WIDTH - 9:0] = {M_res[14:8], 1'b1};
		end
endmodule
module bfloat16_div (
	a,
	b,
	result
);
	parameter WIDTH = 16;
	input wire [WIDTH - 1:0] a;
	input wire [WIDTH - 1:0] b;
	output reg [WIDTH - 1:0] result;
	wire [1:1] sv2v_tmp_FB2B6;
	assign sv2v_tmp_FB2B6 = a[WIDTH - 1] ^ b[WIDTH - 1];
	always @(*) result[WIDTH - 1] = sv2v_tmp_FB2B6;
	wire [7:0] E;
	assign E = a[WIDTH - 2:WIDTH - 8] - b[WIDTH - 2:WIDTH - 8];
	wire [15:0] M_res;
	assign M_res = {1'b0, b[WIDTH - 3:WIDTH - 9]} / {1'b0, a[WIDTH - 3:WIDTH - 9]};
	always @(*)
		if (M_res[15] == 1'b0) begin
			result[WIDTH - 2:WIDTH - 9] = E;
			result[WIDTH - 9:0] = {1'b0, M_res[14:8]};
		end
		else begin
			result[WIDTH - 2:WIDTH - 9] = E - 1'b1;
			result[WIDTH - 9:0] = {M_res[14:8], 1'b1};
		end
endmodule
module vector_regs (
	clk,
	read_addr,
	read_data,
	we,
	write_addr,
	write_data,
	full_we,
	full_write_data,
	registerout_0,
	registerout_1,
	registerout_2,
	registerout_3
);
	parameter WIDTH = 16;
	input wire clk;
	input [1:0] read_addr;
	output reg [255:0] read_data;
	input we;
	input [5:0] write_addr;
	input [WIDTH - 1:0] write_data;
	input full_we;
	input [255:0] full_write_data;
	output wire [255:0] registerout_0;
	output wire [255:0] registerout_1;
	output wire [255:0] registerout_2;
	output wire [255:0] registerout_3;
	reg [255:0] register_0;
	reg [255:0] register_1;
	reg [255:0] register_2;
	reg [255:0] register_3;
	assign registerout_0 = register_0;
	assign registerout_1 = register_1;
	assign registerout_2 = register_2;
	assign registerout_3 = register_3;
	always @(posedge clk) begin
		if (we)
			case (write_addr[5:4])
				2'b00: register_0[write_addr[3:0] * WIDTH+:WIDTH] <= write_data;
				2'b01: register_1[write_addr[3:0] * WIDTH+:WIDTH] <= write_data;
				2'b10: register_2[write_addr[3:0] * WIDTH+:WIDTH] <= write_data;
				2'b11: register_3[write_addr[3:0] * WIDTH+:WIDTH] <= write_data;
			endcase
		if (full_we)
			case (write_addr[5:4])
				2'b00: register_0 <= full_write_data;
				2'b01: register_1 <= full_write_data;
				2'b10: register_2 <= full_write_data;
				2'b11: register_3 <= full_write_data;
			endcase
	end
	always @(*)
		case (read_addr)
			2'b00: read_data = register_0;
			2'b01: read_data = register_1;
			2'b10: read_data = register_2;
			2'b11: read_data = register_3;
			default: read_data = 256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		endcase
endmodule
module scalar_regs (
	clk,
	read_addr,
	read_data,
	we,
	write_addr,
	write_data,
	registers_out
);
	parameter WIDTH = 16;
	parameter NUM_SCALARS = 4;
	input wire clk;
	input [1:0] read_addr;
	output wire [WIDTH - 1:0] read_data;
	input we;
	input [3:0] write_addr;
	input [WIDTH - 1:0] write_data;
	output wire [(NUM_SCALARS * WIDTH) - 1:0] registers_out;
	reg [(NUM_SCALARS * WIDTH) - 1:0] registers;
	assign registers_out = registers;
	always @(posedge clk)
		if (we)
			registers[((NUM_SCALARS - 1) - write_addr) * WIDTH+:WIDTH] <= write_data;
	assign read_data = registers[((NUM_SCALARS - 1) - read_addr) * WIDTH+:WIDTH];
endmodule
module processing_element (
	opcode,
	a_in,
	b_in,
	result
);
	parameter WIDTH = 16;
	input [3:0] opcode;
	input [WIDTH - 1:0] a_in;
	input [WIDTH - 1:0] b_in;
	output reg [WIDTH - 1:0] result;
	wire [WIDTH - 1:0] add_result;
	wire [WIDTH - 1:0] sub_result;
	wire [WIDTH - 1:0] mul_result;
	wire [WIDTH - 1:0] div_result;
	bfloat16_addsub #(.WIDTH(WIDTH)) addsub_instance(
		.a(a_in),
		.b(b_in),
		.result(add_result),
		.is_sub(1'b0)
	);
	bfloat16_addsub #(.WIDTH(WIDTH)) sub_instance(
		.a(a_in),
		.b(b_in),
		.result(sub_result),
		.is_sub(1'b1)
	);
	bfloat16_mul #(.WIDTH(WIDTH)) mul_instance(
		.a(a_in),
		.b(b_in),
		.result(mul_result)
	);
	bfloat16_div #(.WIDTH(WIDTH)) div_instance(
		.a(a_in),
		.b(b_in),
		.result(div_result)
	);
	always @(*)
		case (opcode)
			4'b0001, 4'b0010: result = add_result;
			4'b0011, 4'b0100: result = sub_result;
			4'b0101, 4'b0110: result = mul_result;
			4'b0111, 4'b1000: result = div_result;
			default: result = 0;
		endcase
endmodule
module instruction_decoder (
	inst,
	opcode,
	src1,
	src2,
	dest,
	immediate
);
	input [31:0] inst;
	output wire [3:0] opcode;
	output wire [5:0] src1;
	output wire [5:0] src2;
	output wire [1:0] dest;
	output wire [15:0] immediate;
	assign opcode = inst[31:28];
	assign src1 = inst[27:22];
	assign src2 = inst[21:16];
	assign dest = inst[15:14];
	assign immediate = inst[15:0];
endmodule
module npu (
	wb_clk_i,
	wb_rst_i,
	wbs_stb_i,
	wbs_cyc_i,
	wbs_we_i,
	wbs_dat_i,
	wbs_ack_o,
	wbs_dat_o
);
	parameter WIDTH = 16;
	parameter NUM_VECTORS = 4;
	parameter VECTOR_SIZE = 16;
	parameter NUM_SCALARS = 4;
	input wb_clk_i;
	input wb_rst_i;
	input wbs_stb_i;
	input wbs_cyc_i;
	input wbs_we_i;
	input [31:0] wbs_dat_i;
	output reg wbs_ack_o;
	output reg [31:0] wbs_dat_o;
	wire [255:0] register_0;
	wire [255:0] register_1;
	wire [255:0] register_2;
	wire [255:0] register_3;
	wire [(NUM_SCALARS * WIDTH) - 1:0] scalar_registers;
	wire [3:0] opcode;
	wire [5:0] src1;
	wire [5:0] src2;
	wire [5:0] dest;
	wire [15:0] immediate;
	wire [255:0] vector_read_data;
	wire [15:0] scalar_read_data;
	instruction_decoder decoder(
		.inst(wbs_dat_i),
		.opcode(opcode),
		.src1(src1),
		.src2(src2),
		.dest(dest[5:4]),
		.immediate(immediate)
	);
	reg [1:0] vec_read_addr;
	reg vec_we;
	reg [5:0] vec_write_addr;
	reg [15:0] vec_write_data;
	reg vec_full_we;
	reg [255:0] vec_full_write_data;
	vector_regs vectors(
		.clk(wb_clk_i),
		.read_addr(vec_read_addr),
		.read_data(vector_read_data),
		.we(vec_we),
		.write_addr(vec_write_addr),
		.write_data(vec_write_data),
		.full_we(vec_full_we),
		.full_write_data(vec_full_write_data),
		.registerout_0(register_0),
		.registerout_1(register_1),
		.registerout_2(register_2),
		.registerout_3(register_3)
	);
	wire [1:0] scalar_read_addr;
	reg [WIDTH - 1:0] scalar_write_data;
	reg scalar_we;
	scalar_regs #(
		.WIDTH(WIDTH),
		.NUM_SCALARS(NUM_SCALARS)
	) scalars(
		.clk(wb_clk_i),
		.read_addr(scalar_read_addr),
		.read_data(scalar_read_data),
		.we(scalar_we),
		.write_addr(src2[5:2]),
		.write_data(scalar_write_data),
		.registers_out(scalar_registers)
	);
	reg [WIDTH - 1:0] a_in [0:VECTOR_SIZE - 1];
	reg [WIDTH - 1:0] b_in [0:VECTOR_SIZE - 1];
	wire [WIDTH - 1:0] result [0:VECTOR_SIZE - 1];
	genvar i;
	generate
		for (i = 0; i < VECTOR_SIZE; i = i + 1) begin : pe_gen
			processing_element #(.WIDTH(WIDTH)) pe(
				.opcode(opcode),
				.a_in(a_in[i]),
				.b_in(b_in[i]),
				.result(result[i])
			);
		end
	endgenerate
	reg [(WIDTH * VECTOR_SIZE) - 1:0] result_concat;
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < VECTOR_SIZE; i = i + 1)
			result_concat[i * WIDTH+:WIDTH] = result[i];
	end
	always @(posedge wb_clk_i)
		if (wbs_stb_i && wbs_cyc_i)
			case (opcode)
				4'b0001: begin
					begin : sv2v_autoblock_2
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								case (src2)
									2'b00: b_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: b_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: b_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: b_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0010: begin
					begin : sv2v_autoblock_3
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								b_in[i] <= scalar_read_data;
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0011: begin
					begin : sv2v_autoblock_4
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								case (src2)
									2'b00: b_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: b_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: b_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: b_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0100: begin
					begin : sv2v_autoblock_5
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								b_in[i] <= scalar_read_data;
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0101: begin
					begin : sv2v_autoblock_6
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								case (src2)
									2'b00: b_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: b_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: b_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: b_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0110: begin
					begin : sv2v_autoblock_7
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								b_in[i] <= scalar_read_data;
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b0111: begin
					begin : sv2v_autoblock_8
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								case (src2)
									2'b00: b_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: b_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: b_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: b_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b1000: begin
					begin : sv2v_autoblock_9
						reg signed [31:0] i;
						for (i = 0; i < VECTOR_SIZE; i = i + 1)
							begin
								case (src1)
									2'b00: a_in[i] <= register_0[i * WIDTH+:WIDTH];
									2'b01: a_in[i] <= register_1[i * WIDTH+:WIDTH];
									2'b10: a_in[i] <= register_2[i * WIDTH+:WIDTH];
									2'b11: a_in[i] <= register_3[i * WIDTH+:WIDTH];
								endcase
								b_in[i] <= scalar_read_data;
							end
					end
					vec_write_addr <= dest;
					vec_we <= 1'b0;
					vec_full_we <= 1'b1;
					vec_full_write_data <= result_concat;
				end
				4'b1001: begin
					vec_read_addr <= src2[5:4];
					vec_write_addr <= dest;
					vec_we <= 1'b1;
					vec_full_we <= 1'b0;
					vec_write_data <= immediate;
				end
				4'b1010:
					case (src2)
						2'b00: wbs_dat_o[15:0] <= register_0[immediate * WIDTH+:WIDTH];
						2'b01: wbs_dat_o[15:0] <= register_1[immediate * WIDTH+:WIDTH];
						2'b10: wbs_dat_o[15:0] <= register_2[immediate * WIDTH+:WIDTH];
						2'b11: wbs_dat_o[15:0] <= register_3[immediate * WIDTH+:WIDTH];
					endcase
				4'b1011: begin
					scalar_we <= 1'b1;
					scalar_write_data <= immediate;
				end
				4'b1100: wbs_dat_o[15:0] <= scalar_registers[((NUM_SCALARS - 1) - src2) * WIDTH+:WIDTH];
				default: begin
					vec_we <= 1'b0;
					vec_full_we <= 1'b0;
					scalar_we <= 1'b0;
				end
			endcase
		else begin
			vec_we <= 1'b0;
			vec_full_we <= 1'b0;
			scalar_we <= 1'b0;
		end
	always @(posedge wb_clk_i)
		if (wbs_stb_i && wbs_cyc_i)
			wbs_ack_o <= 1'b1;
		else
			wbs_ack_o <= 1'b0;
endmodule
