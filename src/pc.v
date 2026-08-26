// ============================================================
// Module: pc.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Program counter register. Latches next_pc on every rising clock edge.
//              Async reset drives PC to 0, so simulation starts from a known address.
// Author: github.com/Swarangi-Kale
// ============================================================

module pc #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              reset,
    input  wire [WIDTH-1:0]  next_pc,
    output reg  [WIDTH-1:0]  pc_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= {WIDTH{1'b0}};
        else
            pc_out <= next_pc;
    end

endmodule