// ============================================================
// pc_tb.v
// Testbench for pc.v
//   - Covers reset behavior, normal PC+4-style sequencing,
//     arbitrary jumps/branches (non-sequential next_pc values),
//     and mid-run async reset
// ============================================================

`timescale 1ns / 1ps

module pc_tb;

    reg         clk;
    reg         reset;
    reg  [31:0] next_pc;
    wire [31:0] pc_out;

    pc dut (
        .clk     (clk),
        .reset   (reset),
        .next_pc (next_pc),
        .pc_out  (pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // ---- Case 1: reset drives PC to 0 ----
        reset = 1; next_pc = 32'hf005ba11;  // next_pc irrelevant during reset
        @(negedge clk);
        $display("T1: reset asserted -> pc_out=%h (expect 00000000)", pc_out);

        // ---- Case 2: release reset, feed PC+4-style value ----
        reset = 0; next_pc = 32'h00000004;
        @(negedge clk);
        $display("T2: first PC+4      -> pc_out=%h (expect 00000004)", pc_out);

        // ---- Case 3: sequential increments (mimics PC+4 every cycle) ----
        next_pc = 32'h00000008;
        @(negedge clk);
        $display("T3: second PC+4     -> pc_out=%h (expect 00000008)", pc_out);

        next_pc = 32'h0000000C;
        @(negedge clk);
        $display("T4: third PC+4      -> pc_out=%h (expect 0000000c)", pc_out);

        // ---- Case 5: non-sequential jump (PC doesn't care, just latches it) ----
        next_pc = 32'h00000020;
        @(negedge clk);
        $display("T5: jump target     -> pc_out=%h (expect 00000020)", pc_out);

        // ---- Case 6: branch backward (arbitrary lower address) ----
        next_pc = 32'h00000010;
        @(negedge clk);
        $display("T6: branch backward -> pc_out=%h (expect 00000010)", pc_out);

        // ---- Case 7: async reset mid-run, should take effect immediately, not wait for the next clock edge ----
        next_pc = 32'h00000050;
        @(negedge clk);
        #1;
        reset = 1;
        #1; // small delay after reset asserted, before any clock edge
        $display("T7: async reset mid-run -> pc_out=%h (expect 00000000, no clock edge needed)", pc_out);

        // ---- Case 8: release reset again, confirm normal operation resumes ----
        reset = 0; next_pc = 32'h00000004;
        @(negedge clk);
        $display("T8: resume after reset -> pc_out=%h (expect 00000004)", pc_out);

        $display("Done.");
        $finish;
    end

endmodule