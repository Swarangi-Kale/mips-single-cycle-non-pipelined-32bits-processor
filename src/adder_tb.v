// ============================================================
// adder_tb.v
// Testbench for adder.v
// Tests: PC+4 increment, branch base+offset, general
//        32-bit addition, and edge cases (wraparound, negative
//        offset / backward branch)
// ============================================================

`timescale 1ns / 1ps

module adder_tb;

    reg  [31:0] a, b;
    wire [31:0] sum;

    // Instantiate DUT
    adder dut (
        .a   (a),
        .b   (b),
        .sum (sum)
    );

    initial begin
        // ---- Case 1: normal PC+4 increment ----
        a = 32'h00400000; b = 32'd4;
        #10;
        $display("T1: PC+4 normal      -> a=%h b=%0d sum=%h (expect 00400004)", a, b, sum);

        // ---- Case 2: PC+4 repeated a few instructions later ----
        a = 32'h00400010; b = 32'd4;
        #10;
        $display("T2: PC+4 mid-program -> a=%h b=%0d sum=%h (expect 00400014)", a, b, sum);

        // ---- Case 3: branch target, positive offset (forward branch) ----
        // e.g. PC+4 = 0x00400020, offset already shifted-left-2 = 0x00000010
        a = 32'h00400020; b = 32'h00000010;
        #10;
        $display("T3: branch fwd       -> a=%h b=%h sum=%h (expect 00400030)", a, b, sum);

        // ---- Case 4: branch target, negative offset (backward branch) ----
        // offset = -8, sign-extended and shifted-left-2 -> 0xFFFFFFF8
        a = 32'h00400020; b = 32'hFFFFFFF8;
        #10;
        $display("T4: branch backward  -> a=%h b=%h sum=%h (expect 00400018)", a, b, sum);

        // ---- Case 5: general 32-bit add, arbitrary values (not PC-related) ----
        a = 32'h12345678; b = 32'h0000ABCD;
        #10;
        $display("T5: general add      -> a=%h b=%h sum=%h (expect 12350245)", a, b, sum);

        // ---- Case 6 (edge case): PC+4 overflow/wraparound at top of address space ----
        a = 32'hFFFFFFFC; b = 32'd4;
        #10;
        $display("T6: PC+4 wraparound  -> a=%h b=%0d sum=%h (expect 00000000, wraps silently)", a, b, sum);

        // ---- Case 7 (edge case): branch offset wraps address to just below 0 boundary ----
        a = 32'h00000004; b = 32'hFFFFFFF8; // base=4, offset=-8 -> wraps negative
        #10;
        $display("T7: branch underflow -> a=%h b=%h sum=%h (expect FFFFFFFC, wraps silently)", a, b, sum);

        // ---- Case 8 (edge case): adding zero offset (branch to next instruction / self-loop) ----
        a = 32'h00400040; b = 32'd0;
        #10;
        $display("T8: zero offset      -> a=%h b=%0d sum=%h (expect 00400040)", a, b, sum);

        $display("Done.");
        $finish;
    end

endmodule