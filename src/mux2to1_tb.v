// ============================================================
// mux2to1_tb.v
// Testbench for mux2to1.v - covers normal cases + edge cases + use cases in the processor implementation
// ============================================================

`timescale 1ns / 1ps

module mux2to1_tb;

    reg         sel;
    reg  [31:0] in0, in1;
    wire [31:0] out;

    mux2to1 dut (
        .sel (sel),
        .in0 (in0),
        .in1 (in1),
        .out (out)
    );

    initial begin
        // ---- Case 1: basic sel=0 selects in0 ----
        in0 = 32'h11111111; in1 = 32'h22222222; sel = 0;
        #10;
        $display("T1: sel=0 basic -> out=%h (expect 11111111)", out);

        // ---- Case 2: basic sel=1 selects in1 ----
        sel = 1;
        #10;
        $display("T2: sel=1 basic -> out=%h (expect 22222222)", out);

        // ---- Case 3: in0=0, in1=nonzero, sel=0 (make sure in1 doesn't leak through) ----
        in0 = 32'h00000000; in1 = 32'hAABBCCDE; sel = 0;
        #10;
        $display("T3: in0=0 leak check -> out=%h (expect 00000000)", out);

        // ---- Case 4: same setup, sel=1 ----
        sel = 1;
        #10;
        $display("T4: in1 select -> out=%h (expect aabbccde)", out);

        // ---- Case 5 (ALUSrc scenario): register value vs sign-extended
        //      NEGATIVE immediate, e.g. addi $t0, $t0, -8 ----
        in0 = 32'h00000005;          // register value = 5
        in1 = 32'hFFFFFFF8;          // sign-extended -8
        sel = 1;                      // ALUSrc=1 -> use immediate
        #10;
        $display("T5: ALUSrc neg imm -> out=%h (expect fffffff8)", out);

        // ---- Case 6 (ALUSrc scenario): same instruction type, ALUSrc=0 -> use register ----
        sel = 0;
        #10;
        $display("T6: ALUSrc reg val -> out=%h (expect 00000005)", out);

        // ---- Case 7 (MemtoReg scenario): ALU result vs memory data, both nonzero,
        //      easy to confuse if wires are swapped ----
        in0 = 32'h0000ABCD;   // ALU result
        in1 = 32'hFFFF0000;   // memory read data
        sel = 0;               // MemtoReg=0 -> write back ALU result (e.g. for 'add')
        #10;
        $display("T7: MemtoReg=0 (ALU result) -> out=%h (expect 0000abcd)", out);

        sel = 1;               // MemtoReg=1 -> write back memory data (e.g. for 'lw')
        #10;
        $display("T8: MemtoReg=1 (mem data)  -> out=%h (expect ffff0000)", out);

        // ---- Case 9 (PC-source scenario): PC+4 vs branch target, both valid addresses ----
        in0 = 32'h00400008;   // PC+4 (branch not taken)
        in1 = 32'h00400020;   // branch target (branch taken)
        sel = 0;
        #10;
        $display("T9: branch not taken -> out=%h (expect 00400008)", out);

        sel = 1;
        #10;
        $display("T10: branch taken    -> out=%h (expect 00400020)", out);

        // ---- Case 10 (edge case): identical inputs -- sel shouldn't matter ----
        in0 = 32'hABCDEF01; in1 = 32'hABCDEF01;
        sel = 0;
        #10;
        $display("T11: identical inputs sel=0 -> out=%h (expect abcdef01)", out);
        sel = 1;
        #10;
        $display("T12: identical inputs sel=1 -> out=%h (expect abcdef01)", out);

        // ---- Case 11 (edge case): all-zero vs all-one boundary values ----
        in0 = 32'h00000000; in1 = 32'hFFFFFFFF;
        sel = 0;
        #10;
        $display("T13: all-0 boundary -> out=%h (expect 00000000)", out);
        sel = 1;
        #10;
        $display("T14: all-1 boundary -> out=%h (expect ffffffff)", out);

        // ---- Case 12 (edge case): rapid sel toggling with inputs held constant,
        //      confirming purely combinational response (no clock dependency,
        //      output updates immediately every time sel changes) ----
        in0 = 32'h12345678; in1 = 32'h87654321;
        sel = 0; #2; $display("T15a: rapid toggle sel=0 -> out=%h (expect 12345678)", out);
        sel = 1; #2; $display("T15b: rapid toggle sel=1 -> out=%h (expect 87654321)", out);
        sel = 0; #2; $display("T15c: rapid toggle sel=0 -> out=%h (expect 12345678)", out);
        sel = 1; #2; $display("T15d: rapid toggle sel=1 -> out=%h (expect 87654321)", out);

        $display("Done.");
        $finish;
    end

endmodule