# Verilog PE Assignment Fix

#### You:
module pe #(
    parameter WIDTH = 16
) (
    input logic clk,
    input logic rst_n,


    // Inputs
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic is_sub,
    input logic is_mul,
    input logic is_div,


    // Output
    output logic [WIDTH-1:0] result
);

    bfloat16_addsub #(WIDTH) addsub (
        .a(a),
        .b(b),
        .is_sub(is_sub),
        .result(result)
    );

    bfloat16_mul #(WIDTH) mul (
        .a(a),
        .b(b),
        .result(result)
    );

    bfloat16_div #(WIDTH) div (
        .a(a),
        .b(b),
        .result(result)
    );

    always_comb begin
        if (is_sub)
            addsub.go = 1'b1;
        else if (is_mul)
            mul.go = 1'b1;
        else if (is_div)
            div.go = 1'b1;
    end
endmodule

ILLEGAL_VARIABLE_ASSIGNMENTS: Variable 'result' written by more than one continuous assignment

#### ChatGPT:
In the provided module, you're trying to drive the `result` signal from multiple instances (`addsub`, `mul`, and `div`). In Verilog, you cannot assign a value to a wire from more than one continuous assignment or module instance. If you do, it will create a conflict and will result in the mentioned error.

To solve this issue, you should use multiplexing to ensure only one value is assigned to `result` based on the selected operation. Here's one way to implement this:

```verilog
module pe #(
    parameter WIDTH = 16
) (
    input logic clk,
    input logic rst_n,

    // Inputs
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic is_sub,
    input logic is_mul,
    input logic is_div,

    // Output
    output logic [WIDTH-1:0] result
);

    logic [WIDTH-1:0] addsub_result;
    logic [WIDTH-1:0] mul_result;
    logic [WIDTH-1:0] div_result;

    bfloat16_addsub #(WIDTH) addsub (
        .a(a),
        .b(b),
        .is_sub(is_sub),
        .result(addsub_result) // Connect to intermediate result
    );

    bfloat16_mul #(WIDTH) mul (
        .a(a),
        .b(b),
        .result(mul_result) // Connect to intermediate result
    );

    bfloat16_div #(WIDTH) div (
        .a(a),
        .b(b),
        .result(div_result) // Connect to intermediate result
    );

    always_comb begin
        if (is_sub)
            result = addsub_result;
        else if (is_mul)
            result = mul_result;
        else if (is_div)
            result = div_result;
        else
            result = '0; // Default value, you can change as per requirements
    end

    // I noticed that you tried setting 'go' signals, but these aren't connected in the provided code.
    // You might need to fix those based on the actual interfaces of `bfloat16_addsub`, `bfloat16_mul`, and `bfloat16_div`.

endmodule
```

In the above code, the result of each operation is stored in an intermediate variable (`addsub_result`, `mul_result`, and `div_result`). Then, based on the operation selected (is\_sub, is\_mul, or is\_div), the final `result` is determined using the multiplexer logic implemented in the `always_comb` block.
