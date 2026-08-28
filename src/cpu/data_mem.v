// ============================================================
// Module: data_mem.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Data memory for lw/sw. Read is combinational
//   (always reflects current contents); write is synchronous,
//   happening on the rising clock edge when mem_write is
//   asserted. mem_read is accepted for control-unit interface
//   completeness (RegDst/MemtoReg/MemRead/etc. are all listed
//   as control unit outputs) but does not gate the read output
//   -- in this single-cycle design the output is always valid,
//   and it's simply not selected/written back unless RegWrite
//   is also asserted for an lw instruction, so an unused read
//   value never causes incorrect behavior. Word-addressed
//   internally: byte address bits [1:0] are ignored since all
//   accesses in this ISA are word-aligned.
// Author: github.com/Swarangi-Kale
// ============================================================

module data_mem #(
    parameter MEM_WORDS = 64
)(
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,    // see header note -- not used to gate read_data
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    localparam ADDR_BITS = $clog2(MEM_WORDS);

    reg [31:0] mem [0:MEM_WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;
    end

    // Word-aligned indexing: drop the byte-offset bits [1:0].
    assign read_data = mem[address[ADDR_BITS+1:2]];

    always @(posedge clk) begin
        if (mem_write)
            mem[address[ADDR_BITS+1:2]] <= write_data;
    end

endmodule