# Fix Illegal Net Assignment

#### You:
always_comb begin
        case (opcode)
            4'b001, 4'b010, 4'b011, 4'b100: wbs_dat_o = vector_read_data;
            default: wbs_dat_o = scalar_read_data;
        endcase
    end

ILLEGAL_NET_ASSIGNMENT: Cannot use net 'wbs_dat_o' as left hand side in procedural assignment

#### ChatGPT:
The error you're seeing, `ILLEGAL_NET_ASSIGNMENT`, suggests that you're trying to assign a value to a net (like a wire) inside a procedural block (`always_comb` in this case). In Verilog, nets cannot be assigned values in this way. Instead, you should use a reg or logic type for procedural assignments.

Here's how you might fix the code:

1. Change the declaration of `wbs_dat_o` to `logic` (or `reg` if you're using older Verilog).

```verilog
logic [your_width-1:0] wbs_dat_o; // replace 'your_width' with the appropriate bit-width
```

2. Update the `always_comb` block:

```verilog
always_comb begin
    case (opcode)
        4'b001, 4'b010, 4'b011, 4'b100: wbs_dat_o = vector_read_data;
        default: wbs_dat_o = scalar_read_data;
    endcase
end
```

If `wbs_dat_o` is supposed to connect to some output port that's declared as a wire, you can keep the output port as a wire and connect `wbs_dat_o` to that output wire outside the always block, like:

```verilog
assign out_port = wbs_dat_o;
```

This way, you maintain the proper assignment types and adhere to Verilog's conventions.
