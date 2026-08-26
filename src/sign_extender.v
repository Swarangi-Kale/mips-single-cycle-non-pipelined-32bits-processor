// ============================================================
// sign_extend.v
// Sign-extends a 16-bit immediate to 32 bits.
// Used for all four I-type instructions in this ISA (addi, lw,
// sw, beq) -- all of them sign-extend their immediate/offset
// field, so one module covers every case; no zero-extend
// variant is needed since this ISA has no andi/ori-style
// instructions.
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