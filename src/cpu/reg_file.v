// ============================================================
// Module: reg_file.v
// Project: Single-cycle MIPS processor in Verilog HDL.	
// Description: 32x32 MIPS register file
//   - Two combinational (async) read ports, addressed by rs, rt
//   - One synchronous write port, addressed by rd
//     (NOTE: for lw, the caller must mux rt into the rd port
//      externally, via RegDst -- not handled inside this module)
//   - $zero (register 0) is hardwired: always reads 0,
//     writes to it are ignored
// Author: github.com/Swarangi-Kale
// ============================================================

module reg_file(clk,reg_write, rs, rt, rd, write_data, read_data1, read_data2);

input  wire              clk;       // required for synchronous write
input  wire              reg_write;   // write enable control signal
input  wire [4:0]        rs;          // read address 1
input  wire [4:0]        rt;          // read address 2
input  wire [4:0]        rd;          // write address
input  wire [31:0]  write_data;  // data to write (ALU result, or lw data)
output wire [31:0]   read_data1;  // operand 1
output wire [31:0]  read_data2;   // operand 2


    // 32 general-purpose registers
    reg [31:0] registers [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = {32{1'b0}};
    end

    // Combinational reads, $zero forced to 0 regardless of contents
    assign read_data1 = (rs == 5'd0) ? {32{1'b0}} : registers[rs];
    assign read_data2 = (rt == 5'd0) ? {32{1'b0}} : registers[rt];

    // Synchronous write, $zero write is a no-op
    always @(posedge clk) begin
        if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= write_data;
        end
    end

endmodule
