// Module: alu.v
// Project: Single-cycle MIPS processor in Verilog HDL.	
// Description: Arithmetic logic unit. Currently supports add and sub.
// Author: github.com/Swarangi-Kale

module alu(i_data_a, i_data_b, i_alu_control, o_zero_flag, o_result);

input wire [31:0] i_data_a;					// A operand 
input wire [31:0] i_data_b;					// B operand
output reg [31:0] o_result;				// ALU result
input wire [3:0] i_alu_control;				// Control signal
output wire o_zero_flag;				// Zero flag 

// ---- operation encodings ----
localparam alu_add = 4'b0000;
localparam alu_sub = 4'b0001;
// reserve remaining 14 codes for future ops (AND, OR, SLT, SLL, SRL...)

always @(*) begin
    case (i_alu_control)
        alu_add:	// ADD
		  begin
		      o_result = i_data_a + i_data_b;
		  end
		alu_sub:
		  begin
		      o_result = i_data_a - i_data_b;
		  end
		default:
		  begin
	          o_result = {32{1'bx}};	// x-state, (nor 1, nor 0)
		  end
	endcase
end

// zero flag: used directly by beq (branch taken when ALU computes
// rs - rt and the result is zero)
assign o_zero_flag = (o_result == {32{1'b0}});

endmodule
