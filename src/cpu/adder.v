// ============================================================
// Module: adder.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Generic 32-bit adder, no control signal, no flags.
//              Reused as two separate instances in the datapath:
//                  1) PC + 4              (instruction address increment)
//                  2) (PC+4) + offset<<2  (branch target address)
//              The shift-left-2 of the branch offset happens in a separate module
// Author: github.com/Swarangi-Kale
// ============================================================

module adder #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);

    assign sum = a + b;
    
    /*
    This is unsigned addition. The normal circuitry for addition does unsigned addition.
    Signed addition requires extra ciruitry on top of the basic adder, ehich also enables use of overflow flag. 
    This addition by default wraps around modulo32, removing overflow concept.
    */

endmodule