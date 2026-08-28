// ============================================================
// instr_mem_tb.v
// Testbench for instr_mem.v
//   - Verifies every instruction in the hand-traced test
//     program (instr_mem_init.hex) is fetched correctly by
//     byte address, and confirms combinational (no-clock)
//     read behavior
// ============================================================

// NOTE: IMPORT THE HEX FILE (instr_mem_init.hex) AS A SIMULATION SOURCE TO THE SAME DIRECTORY AS THE TESTBENCH

// Hand-traced test program (instr_mem_init.hex), addresses in
// bytes, covering all 6 ISA instructions:
//   0x00: addi $t0, $zero, 5      -> 20080005
//   0x04: addi $t1, $zero, 10     -> 2009000a
//   0x08: add  $t2, $t0, $t1      -> 01095020   ($t2 = 15)
//   0x0C: sw   $t2, 0($zero)      -> ac0a0000   (mem[0] = 15)
//   0x10: lw   $t3, 0($zero)      -> 8c0b0000   ($t3 = 15)
//   0x14: beq  $t3, $t2, 2        -> 116a0002   (taken, $t3==$t2==15)
//   0x18: addi $t4, $zero, 99     -> 200c0063   (skipped by branch)
//   0x1C: addi $t5, $zero, 55     -> 200d0037   (skipped by branch)
//   0x20: j    0x00                -> 08000000   (branch target)
// ============================================================

`timescale 1ns / 1ps

module instr_mem_tb;

    reg  [31:0] address;
    wire [31:0] instruction;

    instr_mem dut (
        .address     (address),
        .instruction (instruction)
    );

    initial begin
        // ---- Case 1-9: fetch every instruction in program order ----
        address = 32'h00000000; #10;
        $display("T1: addi t0,zero,5   -> addr=%h instr=%h (expect 20080005)", address, instruction);

        address = 32'h00000004; #10;
        $display("T2: addi t1,zero,10  -> addr=%h instr=%h (expect 2009000a)", address, instruction);

        address = 32'h00000008; #10;
        $display("T3: add  t2,t0,t1    -> addr=%h instr=%h (expect 01095020)", address, instruction);

        address = 32'h0000000C; #10;
        $display("T4: sw   t2,0(zero)  -> addr=%h instr=%h (expect ac0a0000)", address, instruction);

        address = 32'h00000010; #10;
        $display("T5: lw   t3,0(zero)  -> addr=%h instr=%h (expect 8c0b0000)", address, instruction);

        address = 32'h00000014; #10;
        $display("T6: beq  t3,t2,2     -> addr=%h instr=%h (expect 116a0002)", address, instruction);

        address = 32'h00000018; #10;
        $display("T7: addi t4,zero,99  -> addr=%h instr=%h (expect 200c0063)", address, instruction);

        address = 32'h0000001C; #10;
        $display("T8: addi t5,zero,55  -> addr=%h instr=%h (expect 200d0037)", address, instruction);

        address = 32'h00000020; #10;
        $display("T9: j    0x00        -> addr=%h instr=%h (expect 08000000)", address, instruction);

        // ---- Case 10 (edge case): address beyond loaded program reads as 0,
        //      not X -- confirms zero-init before $readmemh worked ----
        address = 32'h00000030; #10;
        $display("T10: unloaded addr   -> addr=%h instr=%h (expect 00000000, not X)", address, instruction);

        // ---- Case 11 (edge case): non-word-aligned byte address (bits[1:0] != 0)
        //      still resolves to the containing word, confirming byte-offset
        //      bits are correctly ignored ----
        address = 32'h00000002; #10;
        $display("T11: mid-word addr   -> addr=%h instr=%h (expect 20080005, same word as addr 0)", address, instruction);

        // ---- Case 12: jump backward, re-fetch address 0 to confirm
        //      purely combinational re-read with no clock involved ----
        address = 32'h00000000; #10;
        $display("T12: re-fetch addr0  -> addr=%h instr=%h (expect 20080005)", address, instruction);

        $display("Done.");
        $finish;
    end

endmodule