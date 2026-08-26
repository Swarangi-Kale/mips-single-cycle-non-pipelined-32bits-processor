// ============================================================
// Module: mux2to1.v
// Project: Single-cycle MIPS processor in Verilog HDL.	
// Description: Generic 2:1 multiplexer. Input and output width parameterized, 
//              so same module can be reused in datapaths with different databus lengths.
// Author: github.com/Swarangi-Kale
// ============================================================

module mux2to1 #(
    parameter WIDTH = 32
)(
    input  wire             sel,
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    output wire [WIDTH-1:0] out
);

    assign out = sel ? in1 : in0;

endmodule