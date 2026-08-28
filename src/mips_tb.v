// ============================================================
// mips_tb.v
// Testbench for mips.v
//   Phase 1: use testbench mips_tb_individual_instrs.v
//   Phase 2: reloads the full hand-traced 9-instruction test
//     program (instr_mem_init.hex) and checks final register
//     file / data memory state after a full run, including the
//     beq-taken branch and the j-back-to-0 loop.
//   Self-checking: every check reports PASS/FAIL individually
//   and a final pass/fail count is printed at the end.
// ============================================================

`timescale 1ns / 1ps

module mips_tb;

    reg clk, reset;
    integer pass_count = 0;
    integer fail_count = 0;

    wire [31:0] dbg_pc, dbg_instruction, dbg_alu_result, dbg_write_back_data;
    wire [4:0]  dbg_write_reg,rd_field_debug,destination_reg_debug;
    wire        dbg_reg_write, dbg_branch, dbg_jump, dbg_pc_src, dbg_alu_zero;

    mips dut (
        .clk                  (clk),
        .reset                (reset),
        .dbg_pc               (dbg_pc),
        .dbg_instruction      (dbg_instruction),
        .dbg_alu_result       (dbg_alu_result),
        .dbg_write_back_data  (dbg_write_back_data),
        .dbg_write_reg        (dbg_write_reg),
        .dbg_reg_write        (dbg_reg_write),
        .dbg_branch           (dbg_branch),
        .dbg_jump             (dbg_jump),
        .dbg_pc_src           (dbg_pc_src),
        .dbg_alu_zero         (dbg_alu_zero),
        .rd_field_debug       (rd_field_debug),
        .destination_reg_debug (destination_reg_debug)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Self-checking task. test_name is ASCII-packed into a reg
    // vector (standard Verilog pseudo-string technique) so it
    // can be printed with %s.
    task check;
        input [8*40:1] test_name;
        input [31:0]   actual;
        input [31:0]   expected;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: %-40s actual=%0d expected=%0d", test_name, actual, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %-40s actual=%0d expected=%0d", test_name, actual, expected);
            end
        end
    endtask

    // Runs exactly one instruction from address 0: asserts reset
    // for a full period (snapping pc_out to 0), releases it, then
    // waits exactly one posedge -- during which the instruction at
    // address 0 fetches, executes, and latches its result(s).
    task step_one_instruction;
        begin
            reset = 1;
            @(negedge clk);
            reset = 0;
            @(negedge clk);
        end
    endtask

    initial begin
    
        // ========================================================
        // full hand-traced hex program integration test
        // ========================================================
        $display("---- PHASE 2: full hex program run ----");

        $readmemh("instr_mem_init.hex", dut.imem.mem);
        reset = 1;
        @(negedge clk);
        reset = 0;

        // 9 instructions, run 11 cycles to complete one full pass
        // plus confirm the j-back-to-0 loop starts repeating.
        repeat (11) @(negedge clk);

        check("t0 = 5 (addi)",              dut.regfile.registers[8],  32'd5);
        check("t1 = 10 (addi)",             dut.regfile.registers[9],  32'd10);
        check("t2 = 15 (add)",              dut.regfile.registers[10], 32'd15);
        check("t3 = 15 (lw)",               dut.regfile.registers[11], 32'd15);
        check("t4 = 0 (skipped by beq)",    dut.regfile.registers[12], 32'd0);
        check("t5 = 0 (skipped by beq)",    dut.regfile.registers[13], 32'd0);
        check("data_mem[0] = 15 (sw)",      dut.dmem.mem[0],           32'd15);

        // ========================================================
        // Summary
        // ========================================================
        $display("--------------------------------------------------");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED -- see FAIL lines above");

        $finish;
    end

endmodule