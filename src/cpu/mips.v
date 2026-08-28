// ============================================================
// Module: mips.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Top-level single-cycle datapath for the 6
//   supported instructions (add, addi, lw, sw, beq, j).
//   Instantiates and wires together every previously-built
//   module: pc, instr_mem, reg_file, sign_extend, mux2to1,
//   adder, shift_left2, alu, data_mem, control_unit, and
//   and_gate. Instruction fields are tapped directly off the
//   instruction bus (no separate instr_decoder module -- see
//   project notes for why that's equivalent).
//
//   NOTE: alu.v is instantiated assuming ports named
//   a, b, alu_ctrl, result, zero (per documented ALU
//   interface). Adjust the alu instantiation below if your
//   actual port names differ.
// Author: github.com/Swarangi-Kale
// ============================================================

module mips (
    input  wire        clk,
    input  wire        reset,
    
    output wire [4:0] rd_field_debug,
    output wire [4:0] destination_reg_debug,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instruction,
    output wire [31:0] dbg_alu_result,
    output wire [31:0] dbg_write_back_data,
    output wire [4:0]  dbg_write_reg,
    output wire        dbg_reg_write,
    output wire        dbg_branch,
    output wire        dbg_jump,
    output wire        dbg_pc_src,
    output wire        dbg_alu_zero
);

    // ------------------------------------------------------
    // Instruction fetch
    // ------------------------------------------------------
    wire [31:0] pc_out;
    wire [31:0] instruction;
    wire [31:0] pc_plus4;
    wire [31:0] next_pc;

    pc pc_reg (
        .clk     (clk),
        .reset   (reset),
        .next_pc (next_pc),
        .pc_out  (pc_out)
    );

    instr_mem imem (
        .address     (pc_out),
        .instruction (instruction)
    );

    adder pc_plus4_adder (
        .a   (pc_out),
        .b   (32'd4),
        .sum (pc_plus4)
    );

    // ------------------------------------------------------
    // Instruction field taps (fixed bit positions, see
    // instr_decoder.v notes -- inlined here instead of a
    // separate module)
    // ------------------------------------------------------
    wire [5:0]  opcode = instruction[31:26];
    wire [4:0]  rs     = instruction[25:21];
    wire [4:0]  rt     = instruction[20:16];
    wire [4:0]  rd_field = instruction[15:11];
    wire [5:0]  funct  = instruction[5:0];
    wire [15:0] imm16  = instruction[15:0];
    wire [25:0] addr26 = instruction[25:0];

    // ------------------------------------------------------
    // Control unit
    // ------------------------------------------------------
    wire alu_src, reg_write, reg_dst, mem_to_reg;
    wire branch, jump, mem_read, mem_write;
    wire [3:0] alu_ctrl;

    control_unit ctrl (
        .opcode     (opcode),
        .funct      (funct),
        .alu_src    (alu_src),
        .reg_write  (reg_write),
        .reg_dst    (reg_dst),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .alu_ctrl   (alu_ctrl)
    );

    // ------------------------------------------------------
    // Register file (decode / register read stage)
    // ------------------------------------------------------
    wire [4:0]  write_reg;
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_back_data;
    wire [4:0] destination_reg;

    mux2to1 #(.WIDTH(5)) regdst_mux (
        .sel (reg_dst),
        .in0 (rt),        // lw/addi write to rt
        .in1 (rd_field),  // add writes to rd
        .out (destination_reg)
    );

    reg_file regfile (
        .clk        (clk),
        .reg_write  (reg_write),
        .rs         (rs),
        .rt         (rt),
        .rd         (destination_reg),
        .write_data (write_back_data),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    // ------------------------------------------------------
    // Sign extension
    // ------------------------------------------------------
    wire [31:0] sign_ext_imm;

    sign_extend sext (
        .in  (imm16),
        .out (sign_ext_imm)
    );

    // ------------------------------------------------------
    // Execute stage: ALU and its source mux
    // ------------------------------------------------------
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire        alu_zero_flag;

    mux2to1 alusrc_mux (
        .sel (alu_src),
        .in0 (read_data2),    // add, beq: register operand
        .in1 (sign_ext_imm),  // addi, lw, sw: immediate operand
        .out (alu_b)
    );

    // NOTE: instantiated assuming alu.v ports are a, b, alu_ctrl,
    // result, zero -- adjust to match your actual alu.v if different.
    alu alu_unit (
        .i_data_a        (read_data1),
        .i_data_b        (alu_b),
        .i_alu_control (alu_ctrl),
        .o_result   (alu_result),
        .o_zero_flag     (alu_zero_flag)
    );

    // ------------------------------------------------------
    // Memory stage
    // ------------------------------------------------------
    wire [31:0] mem_read_data;

    data_mem dmem (
        .clk        (clk),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .address    (alu_result),
        .write_data (read_data2),   // sw stores the rt value
        .read_data  (mem_read_data)
    );

    // ------------------------------------------------------
    // Write-back stage
    // ------------------------------------------------------
    mux2to1 memtoreg_mux (
        .sel (mem_to_reg),
        .in0 (alu_result),     // add, addi write back the ALU result
        .in1 (mem_read_data),  // lw writes back memory data
        .out (write_back_data)
    );

    // ------------------------------------------------------
    // Branch target calculation
    // ------------------------------------------------------
    wire [31:0] branch_offset_shifted;
    wire [31:0] branch_target;
    wire        pc_src;
    wire [31:0] pc_after_branch;

    shift_left2 branch_shift (
        .in  (sign_ext_imm),
        .out (branch_offset_shifted)
    );

    adder branch_adder (
        .a   (pc_plus4),
        .b   (branch_offset_shifted),
        .sum (branch_target)
    );

    and_gate branch_and (
        .in_1 (branch),
        .in_2   (alu_zero_flag),
        .out (pc_src)
    );

    mux2to1 branch_mux (
        .sel (pc_src),
        .in0 (pc_plus4),       // branch not taken
        .in1 (branch_target),  // branch taken
        .out (pc_after_branch)
    );

    // ------------------------------------------------------
    // Jump target calculation
    // ------------------------------------------------------
    wire [27:0] jump_addr_shifted;
    wire [31:0] jump_target;

    shift_left2 #(.IN_WIDTH(26), .OUT_WIDTH(28)) jump_shift (
        .in  (addr26),
        .out (jump_addr_shifted)
    );

    // Jump target = top 4 bits of PC+4 concatenated with the
    // shifted 26-bit address field -- pure wiring, no adder.
    assign jump_target = {pc_plus4[31:28], jump_addr_shifted};

    // ------------------------------------------------------
    // Final PC-source mux: jump takes priority over branch/PC+4
    // ------------------------------------------------------
    mux2to1 jump_mux (
        .sel (jump),
        .in0 (pc_after_branch),  // PC+4 or branch target
        .in1 (jump_target),      // j overrides everything
        .out (next_pc)
    );

assign dbg_pc              = pc_out;
assign dbg_instruction     = instruction;
assign dbg_alu_result      = alu_result;
assign dbg_write_back_data = write_back_data;
assign dbg_write_reg       = destination_reg;
assign dbg_reg_write       = reg_write;
assign dbg_branch          = branch;
assign dbg_jump            = jump;
assign dbg_pc_src          = pc_src;
assign dbg_alu_zero        = alu_zero_flag;
assign rd_field_debug      = rd_field;
assign destination_reg_debug= destination_reg;

endmodule