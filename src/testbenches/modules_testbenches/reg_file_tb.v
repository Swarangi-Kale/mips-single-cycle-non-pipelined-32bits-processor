// ============================================================
// reg_file_tb.v
// Testbench for reg_file.v
// ============================================================

`timescale 1ns / 1ps

module reg_file_tb;

    reg         clk;
    reg         reg_write;
    reg  [4:0]  rs, rt, rd;
    reg  [31:0] write_data;
    wire [31:0] read_data1, read_data2;

    // Instantiate DUT
    reg_file dut (
        .clk        (clk),
        .reg_write  (reg_write),
        .rs         (rs),
        .rt         (rt),
        .rd         (rd),
        .write_data (write_data),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("reg_file_tb.vcd");
        $dumpvars(0, reg_file_tb);
    end

    initial begin
        // ---- Stimulus 1: write $t0 ($8) = 10, no read yet ----
        reg_write = 0; rs = 0; rt = 0; rd = 0; write_data = 0;
        @(negedge clk);
        reg_write = 1; rd = 5'd8; write_data = 32'd10;
        @(negedge clk);   // write happens on the posedge in between
        reg_write = 0;

        // ---- Stimulus 2: read $t0 back on both ports ----
        rs = 5'd8; rt = 5'd8;
        #1;
        $display("T1: read $t0 twice -> read_data1=%0d read_data2=%0d (expect 10, 10)", read_data1, read_data2);

        // ---- Stimulus 3: write $t1 ($9) = 25, read $t0 and $t1 same cycle ----
        @(negedge clk);
        reg_write = 1; rd = 5'd9; write_data = 32'd25;
        rs = 5'd8; rt = 5'd9;    // reading $t1 before the write has landed
        #1;
        $display("T2: mid-write read -> read_data1=%0d read_data2=%0d (expect 10, old $t1 value 0)", read_data1, read_data2);

        @(negedge clk);
        reg_write = 0;
        #1;
        $display("T3: after write settles -> read_data2=%0d (expect 25)", read_data2);

        // ---- Stimulus 4: attempt to write $zero -> must stay 0 ----
        @(negedge clk);
        reg_write = 1; rd = 5'd0; write_data = 32'hFFFFFFFF;
        @(negedge clk);
        reg_write = 0;
        rs = 5'd0;
        #1;
        $display("T4: write attempt to $zero -> read_data1=%0d (expect 0)", read_data1);

        // ---- Stimulus 5: back-to-back writes to same register ----
        @(negedge clk);
        reg_write = 1; rd = 5'd16; write_data = 32'd100;   // $s0 = 100
        @(negedge clk);
        rd = 5'd16; write_data = 32'd200;                  // $s0 = 200
        @(negedge clk);
        reg_write = 0;
        rs = 5'd16;
        #1;
        $display("T5: back-to-back write $s0 -> read_data1=%0d (expect 200)", read_data1);

        // ---- Stimulus 6: reg_write=0 write attempt should be ignored ----
        @(negedge clk);
        reg_write = 0; rd = 5'd17; write_data = 32'd999;   // $s1, but reg_write not asserted
        @(negedge clk);
        rt = 5'd17;
        #1;
        $display("T6: write with reg_write=0 -> read_data2=%0d (expect 0)", read_data2);

        // ---- Stimulus 7: lw-style write -- rd port fed with rt value externally ----
        // (simulating what the RegDst mux would hand this module for an lw instruction:
        //  the instruction's rt field arrives on the "rd" port from outside)
        @(negedge clk);
        reg_write = 1; rd = 5'd12; write_data = 32'd555;   // pretend rt=12 was muxed onto rd
        @(negedge clk);
        reg_write = 0;
        rs = 5'd12;
        #1;
        $display("T7: lw-style write via muxed rd=rt -> read_data1=%0d (expect 555)", read_data1);

        #10;
        $display("Done.");
        $finish;
    end

endmodule
