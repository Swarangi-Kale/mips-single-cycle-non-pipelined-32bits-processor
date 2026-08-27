// ============================================================
// and_gate_tb.v
// Testbench for and_gate.v
//   - Covers all 4 input combinations, plus the two realistic
//     processor scenarios: beq with equal operands (branch
//     taken) and beq with unequal operands (branch not taken),
//     and confirms non-beq instructions never take pc_src=1
//     regardless of what zero happens to be
// ============================================================

`timescale 1ns / 1ps

module and_gate_tb;

    reg  branch, zero;
    wire pc_src;

    and_gate dut (
        .in_1 (branch),
        .in_2   (zero),
        .out (pc_src)
    );

    initial begin
        // ---- Case 1: branch=0, zero=0 ----
        branch = 0; zero = 0;
        #10;
        $display("T1: branch=0 zero=0 -> pc_src=%b (expect 0)", pc_src);

        // ---- Case 2: branch=0, zero=1 (non-beq instruction, ALU result
        //      happens to be zero e.g. add $t0,$zero,$zero -- must NOT branch) ----
        branch = 0; zero = 1;
        #10;
        $display("T2: branch=0 zero=1 -> pc_src=%b (expect 0, non-beq instr never branches)", pc_src);

        // ---- Case 3: branch=1, zero=0 (beq, operands NOT equal -> not taken) ----
        branch = 1; zero = 0;
        #10;
        $display("T3: branch=1 zero=0 -> pc_src=%b (expect 0, beq not taken)", pc_src);

        // ---- Case 4: branch=1, zero=1 (beq, operands equal -> taken) ----
        branch = 1; zero = 1;
        #10;
        $display("T4: branch=1 zero=1 -> pc_src=%b (expect 1, beq taken)", pc_src);

        $display("Done.");
        $finish;
    end

endmodule