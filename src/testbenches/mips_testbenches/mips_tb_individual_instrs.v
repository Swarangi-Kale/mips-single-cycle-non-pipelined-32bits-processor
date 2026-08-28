// ============================================================
// mips_tb_individual_instrs.v
// Testbench for mips.v
//   Phase 1: directed, single-instruction tests for each of the
//     6 instructions (add, addi, lw, sw, beq-taken, beq-not-
//     taken, j), each set up and checked in isolation using
//     hierarchical backdoor access to instr_mem/reg_file/
//     data_mem's internal arrays. Uses $s0-$s7 (registers
//     16-23) and data_mem word indices 3-4, kept deliberately
//     separate from the $t-registers and word index 0 used by
//     the Phase 2 program, so the two phases can't cross-
//     contaminate each other's results.
//   Phase 2: use the testbench file mips_tb.v
//   Self-checking: every check reports PASS/FAIL individually
//   and a final pass/fail count is printed at the end.
// ============================================================

`timescale 1ns / 1ps

module mips_tb_individual_instrs;

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
        // PHASE 1: directed single-instruction tests
        // ========================================================
        $display("---- PHASE 1: per-instruction directed tests ----");

        // ---- T1: add $s2, $s0, $s1 ----
        dut.regfile.registers[16] = 32'd7;   // $s0
        dut.regfile.registers[17] = 32'd13;  // $s1
        dut.imem.mem[0] = 32'h02119020;      // add $s2,$s0,$s1
        step_one_instruction;
        
        check("add: s2 = s0+s1",        dut.regfile.registers[18], 32'd20);
        check("add: pc after = PC+4",   dut.pc_out,                32'd4);

        // ---- T2: addi $s3, $zero, 42 ----
        dut.imem.mem[0] = 32'h2013002A;      // addi $s3,$zero,42
        step_one_instruction;
        check("addi: s3 = 42",          dut.regfile.registers[19], 32'd42);
        check("addi: pc after = PC+4",  dut.pc_out,                32'd4);

        // ---- T3: lw $s4, 12($zero) ----
        dut.dmem.mem[3] = 32'd88;            // word index 3 = byte addr 12
        dut.imem.mem[0] = 32'h8C14000C;      // lw $s4,12($zero)
        step_one_instruction;
        check("lw: s4 = mem[12]",       dut.regfile.registers[20], 32'd88);
        check("lw: pc after = PC+4",    dut.pc_out,                32'd4);

        // ---- T4: sw $s5, 16($zero) ----
        dut.regfile.registers[21] = 32'd99;  // $s5, value to store
        dut.imem.mem[0] = 32'hAC150010;      // sw $s5,16($zero)
        step_one_instruction;
        check("sw: mem[16] = s5",       dut.dmem.mem[4],           32'd99);
        check("sw: pc after = PC+4",    dut.pc_out,                32'd4);

        // ---- T5a: beq $s6, $s7, 5 -- TAKEN (equal operands) ----
        dut.regfile.registers[22] = 32'd100; // $s6
        dut.regfile.registers[23] = 32'd100; // $s7 (equal -> taken)
        dut.imem.mem[0] = 32'h12D70005;      // beq $s6,$s7,5
        step_one_instruction;
        check("beq taken: pc = PC+4+20", dut.pc_out,               32'd24);

        // ---- T5b: beq $s6, $s7, 5 -- NOT TAKEN (unequal operands) ----
        dut.regfile.registers[22] = 32'd100; // $s6
        dut.regfile.registers[23] = 32'd55;  // $s7 (unequal -> not taken)
        // mem[0] still holds the same beq instruction from T5a
        step_one_instruction;
        check("beq not taken: pc = PC+4", dut.pc_out,              32'd4);

        // ---- T6: j to word address 10 (byte address 0x28) ----
        dut.imem.mem[0] = 32'h0800000A;      // j word 10
        step_one_instruction;
        check("j: pc = jump target",    dut.pc_out,                32'h00000028);
        
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