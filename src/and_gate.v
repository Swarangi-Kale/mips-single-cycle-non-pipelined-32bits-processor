// ============================================================
// Module: and_gate.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: 1-bit AND gate. Combines the control unit's
//   Branch signal with the ALU's zero flag to produce pc_src,
//   which drives the PC-source mux: pc_src=1 selects the
//   branch target, pc_src=0 selects PC+4. Only meaningful for
//   beq (Branch=1) -- for every other instruction Branch=0
//   forces pc_src=0 regardless of what zero_flag happens to be.
// Author: github.com/Swarangi-Kale
// ============================================================

module and_gate (
    input  wire in_1,
    input  wire in_2,
    output wire out
);

    assign out = in_1 & in_2;

endmodule