// ============================================================
// data_mem_tb.v
// Testbench for data_mem.v
//   - Covers basic write/read-back, mem_write=0 no-op,
//     mem_read having no effect on the output (by design),
//     word-aligned byte-address collapsing, and the sw/lw
//     scenario from the hand-traced test program (storing and
//     reloading $t2 = 15 at address 0)
// ============================================================

`timescale 1ns / 1ps

module data_mem_tb;

    reg         clk;
    reg         mem_write, mem_read;
    reg  [31:0] address, write_data;
    wire [31:0] read_data;

    data_mem dut (
        .clk        (clk),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // ---- Case 1: read before any write -- should be 0 ----
        mem_write = 0; mem_read = 1; address = 32'h00000000; write_data = 0;
        #10;
        $display("T1: read before write -> read_data=%h (expect 00000000)", read_data);

        // ---- Case 2 (sw/lw scenario): store $t2=15 at address 0 ----
        @(negedge clk);
        mem_write = 1; address = 32'h00000000; write_data = 32'd15;
        @(negedge clk);
        mem_write = 0;
        #1;
        $display("T2: sw t2,0(zero) -> read_data=%h (expect 0000000f)", read_data);

        // ---- Case 3 (sw/lw scenario): lw reloads the same value ----
        mem_read = 1;
        #1;
        $display("T3: lw t3,0(zero) -> read_data=%h (expect 0000000f)", read_data);

        // ---- Case 4: write to a different address, confirm addr 0 unaffected ----
        @(negedge clk);
        mem_write = 1; address = 32'h00000004; write_data = 32'hCAFEBABE;
        @(negedge clk);
        mem_write = 0;
        address = 32'h00000000;
        #1;
        $display("T4: addr0 unaffected -> read_data=%h (expect 0000000f)", read_data);

        address = 32'h00000004;
        #1;
        $display("T5: addr4 new value  -> read_data=%h (expect cafebabe)", read_data);

        // ---- Case 6: mem_write=0 write attempt is ignored ----
        @(negedge clk);
        mem_write = 0; address = 32'h00000008; write_data = 32'hFFFFFFFF;
        @(negedge clk);
        #1;
        $display("T6: write with mem_write=0 -> read_data=%h (expect 00000000)", read_data);

        // ---- Case 7 (edge case, design decision check): mem_read=0 does NOT
        //      gate read_data -- output still reflects memory contents ----
        address = 32'h00000000; mem_read = 0;
        #1;
        $display("T7: mem_read=0, addr0 -> read_data=%h (expect 0000000f, mem_read does not gate output)", read_data);

        // ---- Case 8 (edge case): non-word-aligned byte address collapses to
        //      the containing word (bits[1:0] ignored) ----
        address = 32'h00000006; // bytes 4-7 map to the same word as addr 4
        #1;
        $display("T8: mid-word addr    -> addr=%h read_data=%h (expect cafebabe, same word as addr4)", address, read_data);

        // ---- Case 9: back-to-back writes to the same address, last write wins ----
        @(negedge clk);
        mem_write = 1; address = 32'h0000000C; write_data = 32'd100;
        @(negedge clk);
        write_data = 32'd200;
        @(negedge clk);
        mem_write = 0;
        address = 32'h0000000C;
        #1;
        $display("T9: back-to-back write -> read_data=%h (expect 000000c8, i.e. 200 decimal)", read_data);

        $display("Done.");
        $finish;
    end

endmodule