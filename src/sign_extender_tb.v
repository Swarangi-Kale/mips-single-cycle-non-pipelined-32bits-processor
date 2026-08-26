// ============================================================
// sign_extend_tb.v
// Testbench for sign_extend.v
//   - Covers positive values, negative values, boundary values,
//     and realistic addi/lw/sw/beq immediate examples
// ============================================================

`timescale 1ns / 1ps

module sign_extend_tb;

    reg  [15:0] in;
    wire [31:0] out;

    sign_extend dut (
        .in  (in),
        .out (out)
    );

    initial begin
        // ---- Case 1: small positive value ----
        in = 16'h0004;
        #10;
        $display("T1: small positive        -> in=%h out=%h (expect 00000004)", in, out);

        // ---- Case 2: max positive 16-bit signed value (0x7FFF = +32767) ----
        in = 16'h7FFF;
        #10;
        $display("T2: max positive boundary -> in=%h out=%h (expect 00007fff)", in, out);

        // ---- Case 3: -1 (all ones) ----
        in = 16'hFFFF;
        #10;
        $display("T3: -1 (all ones)         -> in=%h out=%h (expect ffffffff)", in, out);

        // ---- Case 4: max negative 16-bit signed value (0x8000 = -32768) ----
        in = 16'h8000;
        #10;
        $display("T4: max negative boundary -> in=%h out=%h (expect ffff8000)", in, out);

        // ---- Case 5: zero ----
        in = 16'h0000;
        #10;
        $display("T5: zero                  -> in=%h out=%h (expect 00000000)", in, out);

        // ---- Case 6 (addi scenario): addi $t0, $t0, -8 ----
        in = 16'hFFF8;
        #10;
        $display("T6: addi imm = -8         -> in=%h out=%h (expect fffffff8)", in, out);

        // ---- Case 7 (lw/sw scenario): positive byte offset, e.g. lw $t0, 16($sp) ----
        in = 16'h0010;
        #10;
        $display("T7: lw/sw offset = 16     -> in=%h out=%h (expect 00000010)", in, out);

        // ---- Case 8 (beq scenario): negative branch offset, e.g. beq backward by -4 words ----
        in = 16'hFFFC;
        #10;
        $display("T8: beq offset = -4       -> in=%h out=%h (expect fffffffc)", in, out);

        // ---- Case 9: arbitrary mid-range positive value ----
        in = 16'h1234;
        #10;
        $display("T9: arbitrary positive    -> in=%h out=%h (expect 00001234)", in, out);

        // ---- Case 10: arbitrary mid-range value with sign bit set ----
        in = 16'h8ABC;
        #10;
        $display("T10: arbitrary negative   -> in=%h out=%h (expect ffff8abc)", in, out);

        $display("Done.");
        $finish;
    end

endmodule