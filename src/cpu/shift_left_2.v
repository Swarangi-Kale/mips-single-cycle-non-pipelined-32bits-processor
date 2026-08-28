// ============================================================
// Module: shift_left2.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Fixed shift-left-by-2 (multiply by 4, word alignment).
//              Implemented as bit concatenation
// Author: github.com/Swarangi-Kale
// ============================================================

module shift_left2 #(
    parameter IN_WIDTH  = 32,
    parameter OUT_WIDTH = 32
)(
    input  wire [IN_WIDTH-1:0]  in,
    output wire [OUT_WIDTH-1:0] out
);

    // Shifting left by 2 via concatenation grows the width by 2 bits.
    wire [IN_WIDTH+1:0] shifted = {in, 2'b00};
    assign out = shifted[OUT_WIDTH-1:0];
    
// Reused for two different cases with two different width
// configurations:
//   1) Branch target offset:  IN_WIDTH=32, OUT_WIDTH=32
//      (sign-extended 32-bit offset, shifted left 2; the top 2
//       bits that fall off are always redundant copies of the
//       sign bit, so no real information is lost)
//   2) Jump target address:   IN_WIDTH=26, OUT_WIDTH=28
//      (26-bit instruction address field grows to 28 bits;
//       these 28 bits then get concatenated with PC+4[31:28]
//       elsewhere in the datapath -- not handled by this module)

endmodule