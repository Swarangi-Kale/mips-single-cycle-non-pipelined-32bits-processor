// ============================================================
// Module: instr_mem.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Instruction memory, modeled as a combinational
//   ROM (no clock -- fetch must complete within the same cycle
//   as decode/execute/writeback in a single-cycle design).
//   Word-addressed internally: byte address bits [1:0] are
//   ignored since all instructions are word-aligned. Preloaded
//   via $readmemh from a hex file at elaboration time.
// Author: github.com/Swarangi-Kale
// ============================================================

module instr_mem #(
    parameter MEM_WORDS = 64,
    parameter INIT_FILE = "instr_mem_init.hex"
)(
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    localparam ADDR_BITS = $clog2(MEM_WORDS);

    reg [31:0] mem [0:MEM_WORDS-1];

    integer i;
    initial begin
        // Zero-init first so any addresses beyond the loaded
        // program read as 0 instead of X in simulation.
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;
//        $readmemh(INIT_FILE, mem);
    end

    // Word-aligned indexing: drop the byte-offset bits [1:0].
    assign instruction = mem[address[ADDR_BITS+1:2]];

endmodule