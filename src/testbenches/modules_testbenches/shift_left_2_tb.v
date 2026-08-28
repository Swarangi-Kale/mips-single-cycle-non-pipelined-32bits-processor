// ============================================================
// shift_left2_tb.v
// Testbench for shift_left2.v
//   - Instantiates the module TWICE with different parameters,
//     mirroring its two real uses in the datapath:
//       dut_branch: IN_WIDTH=32, OUT_WIDTH=32 (branch offset)
//       dut_jump:   IN_WIDTH=26, OUT_WIDTH=28 (jump address)
// ============================================================

`timescale 1ns / 1ps

module shift_left2_tb;

    // ---- Branch-offset instance (32 -> 32) ----
    reg  [31:0] branch_in;
    wire [31:0] branch_out;

    shift_left2 #(.IN_WIDTH(32), .OUT_WIDTH(32)) dut_branch (
        .in  (branch_in),
        .out (branch_out)
    );

    // ---- Jump-address instance (26 -> 28) ----
    reg  [25:0] jump_in;
    wire [27:0] jump_out;

    shift_left2 #(.IN_WIDTH(26), .OUT_WIDTH(28)) dut_jump (
        .in  (jump_in),
        .out (jump_out)
    );

    initial begin
        // ==================================================
        // Branch-offset test cases (sign-extended 32-bit input)
        // ==================================================

        // ---- Case 1: small positive offset (e.g. sign-extended +4) ----
        branch_in = 32'h00000004;
        #10;
        $display("T1 (branch): +4 words   -> in=%h out=%h (expect 00000010)", branch_in, branch_out);

        // ---- Case 2: zero offset ----
        branch_in = 32'h00000000;
        #10;
        $display("T2 (branch): 0 words    -> in=%h out=%h (expect 00000000)", branch_in, branch_out);

        // ---- Case 3: sign-extended negative offset (-8), all top bits are 1s ----
        branch_in = 32'hFFFFFFF8;
        #10;
        $display("T3 (branch): -8 words   -> in=%h out=%h (expect ffffffe0)", branch_in, branch_out);

        // ---- Case 4: max positive sign-extended immediate (0x00007FFF) ----
        branch_in = 32'h00007FFF;
        #10;
        $display("T4 (branch): max +imm   -> in=%h out=%h (expect 0001fffc)", branch_in, branch_out);

        // ---- Case 5: max negative sign-extended immediate (0xFFFF8000) ----
        branch_in = 32'hFFFF8000;
        #10;
        $display("T5 (branch): max -imm   -> in=%h out=%h (expect fffe0000)", branch_in, branch_out);

        // ---- Case 6 (edge case): top 2 bits dropped are redundant sign copies,
        //      confirm this holds even at the widest negative value ----
        branch_in = 32'hFFFFFFFF; // -1
        #10;
        $display("T6 (branch): -1         -> in=%h out=%h (expect fffffffc)", branch_in, branch_out);

        // ==================================================
        // Jump-address test cases (26-bit instr field, no bits lost)
        // ==================================================

        // ---- Case 7: small jump address field ----
        jump_in = 26'h0000004;
        #10;
        $display("T7 (jump): small addr   -> in=%h out=%h (expect 0000010)", jump_in, jump_out);

        // ---- Case 8: zero ----
        jump_in = 26'h0000000;
        #10;
        $display("T8 (jump): zero addr    -> in=%h out=%h (expect 0000000)", jump_in, jump_out);

        // ---- Case 9: max 26-bit value, verify no truncation (28-bit output holds it fully) ----
        jump_in = 26'h3FFFFFF; // all 26 bits set
        #10;
        $display("T9 (jump): max addr     -> in=%h out=%h (expect ffffffc, all 26 input bits preserved, no truncation)", jump_in, jump_out);

        // ---- Case 10: arbitrary mid-range jump address ----
        jump_in = 26'h0100000;
        #10;
        $display("T10 (jump): mid addr    -> in=%h out=%h (expect 0400000)", jump_in, jump_out);

        $display("Done.");
        $finish;
    end

endmodule