// ============================================================
// Module: sign_extend.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Sign-extends a 16-bit immediate to 32 bits.
// Author: github.com/Swarangi-Kale
// ============================================================

module sign_extend #(
    parameter IN_WIDTH  = 16,
    parameter OUT_WIDTH = 32
)(
    input  wire [IN_WIDTH-1:0]  in,
    output wire [OUT_WIDTH-1:0] out
);

    // Replicate the sign bit (MSB of the input) to fill the upper bits, 
    // then concatenate with the original input.
    assign out = {{(OUT_WIDTH-IN_WIDTH){in[IN_WIDTH-1]}}, in};

endmodule