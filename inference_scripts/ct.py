from ctransformers import AutoModelForCausalLM

# Set gpu_layers to the number of layers to offload to GPU. Set to 0 if no GPU acceleration is available on your system.
llm = AutoModelForCausalLM.from_pretrained("TheBloke/WizardCoder-Python-34B-V1.0-GGUF", model_file="/cta/research/level0/LLM/models/wizardcoder-python-34b-v1.0.Q5_K_M.gguf", model_type="llama", gpu_layers=32)

for text in llm("Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n### Instruction:\nDesign an NPU coprocessor for accelerating common machine learning operations. This NPU will receive data from a RISC-V cpu via a 32 bit wishbone bus. The wishbone bus has the signals input wb_clk_i, input wb_rst_i, input wbs_stb_i, input wbs_cyc_i, input wbs_we_i, input [3:0] wbs_sel_i, input [31:0] wbs_dat_i, input [31:0] wbs_adr_i, output wbs_ack_o, output [31:0] wbs_dat_o. This accelerator will accept memory locations starting from 0x30000000 from the wishbone address bus. The 0x30000000 address will be used to receive instructions, starting from 0x30000001 32bit portions of the vector registers and 16 bit scalar registers will be mapped. When the wishbone address signal is set to register locations main CPU will read or write using the wishbone data signals. This NPU uses bfloat16 as the native data type. The NPU will have 16 vector registers that can each hold 16 bfloat16 values (each vector register is 256 bits) and 16 scalar registers each holding 1 bfloat16 value. Because the data bus is 32 bits the RISC-V cpu will read/write 32 bit portions of the vector registers at a time, keep that in mind. The NPU will use processing elements for execution. Implement all necessary modules completely in SystemVerilog for this NPU.\n\n### Response:\nHere are the modules and their complete implementations:\n\n", stream=True):
    print(text, end="", flush=True)