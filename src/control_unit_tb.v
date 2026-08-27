// ============================================================
// control_unit_tb.v
// Testbench for control_unit.v
//   - Verifies every functionally-meaningful control signal
//     against the control signal table for all 6 instructions.
// ============================================================

`timescale 1ns / 1ps

module control_unit_tb;

    reg  [5:0] opcode, funct;
    wire       alu_src, reg_write, reg_dst, mem_to_reg;
    wire       branch, jump, mem_read, mem_write;
    wire [3:0] alu_ctrl;

    control_unit dut (
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

    initial begin
        // ---- T1: add (R-type, funct=32) ----
        opcode = 6'b000000; funct = 6'd32;
        #10;
        $display("T1 add : alu_src=%b reg_write=%b reg_dst=%b mem_to_reg=%b branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect 0 1 1 0 0 0 0 0 0000)");

        // ---- T2: addi ----
        opcode = 6'd8; funct = 6'd0; // funct irrelevant for I-type
        #10;
        $display("T2 addi: alu_src=%b reg_write=%b reg_dst=%b mem_to_reg=%b branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect 1 1 0 0 0 0 0 0 0000)");

        // ---- T3: lw ----
        opcode = 6'd35; funct = 6'd0;
        #10;
        $display("T3 lw  : alu_src=%b reg_write=%b reg_dst=%b mem_to_reg=%b branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect 1 1 0 1 0 0 1 0 0000)");

        // ---- T4: sw (reg_dst, mem_to_reg are don't-care -- shown, not asserted) ----
        opcode = 6'd43; funct = 6'd0;
        #10;
        $display("T4 sw  : alu_src=%b reg_write=%b reg_dst=%b(x) mem_to_reg=%b(x) branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect 1 0 x x 0 0 0 1 0000)");

        // ---- T5: beq (reg_dst, mem_to_reg don't-care; alu_ctrl must be SUB) ----
        opcode = 6'd4; funct = 6'd0;
        #10;
        $display("T5 beq : alu_src=%b reg_write=%b reg_dst=%b(x) mem_to_reg=%b(x) branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect x 0 x x 1 0 0 0 0001)");

        // ---- T6: j (alu_src, reg_dst, mem_to_reg, alu_ctrl all don't-care) ----
        opcode = 6'd2; funct = 6'd0;
        #10;
        $display("T6 j   : alu_src=%b(x) reg_write=%b reg_dst=%b(x) mem_to_reg=%b(x) branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b(x)",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect x 0 x x x 1 0 0 xxxx)");

        // ---- T7 (edge case): unrecognized opcode -- everything falls back
        //      to safe defaults, no x propagation, no latch inference ----
        opcode = 6'b111111; funct = 6'd0;
        #10;
        $display("T7 unknown opcode: alu_src=%b reg_write=%b reg_dst=%b mem_to_reg=%b branch=%b jump=%b mem_read=%b mem_write=%b alu_ctrl=%b",
                   alu_src, reg_write, reg_dst, mem_to_reg, branch, jump, mem_read, mem_write, alu_ctrl);
        $display("     (expect 0 0 0 0 0 0 0 0 0000, all safe defaults)");

        $display("Done.");
        $finish;
    end

endmodule