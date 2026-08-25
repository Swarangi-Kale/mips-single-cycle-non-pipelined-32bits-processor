//// =============================================================
//// alu_tb.v
//// Simple testbench: instantiates ALU, applies 2 ADD and 2 SUB
//// test cases directly, no tasks/functions. Meant for waveform viewing.
//// =============================================================

//`timescale 1ns/1ps

//module alu_tb;

//    reg  [31:0] a, b;
//    reg  [3:0]  alu_ctrl;
//    wire [31:0] result;
//    wire        zero;

//    localparam ALU_ADD = 4'b0000;
//    localparam ALU_SUB = 4'b0001;

//    // instantiate the ALU
//    alu DUT (
//        .i_data_a(a),
//        .i_data_b(b),
//        .i_alu_control(alu_ctrl),
//        .o_result(result),
//        .o_zero_flag(zero)
//    );

//    initial begin
//        // ---- ADD test case 1: simple positive addition ----
//        a = 32'd15;
//        b = 32'd10;
//        alu_ctrl = ALU_ADD;
//        #10;

//        // ---- ADD test case 2: operands that sum to zero ----
//        a = 32'd20;
//        b = -32'd20;
//        alu_ctrl = ALU_ADD;
//        #10;

//        // ---- SUB test case 1: simple subtraction ----
//        a = 32'd50;
//        b = 32'd30;
//        alu_ctrl = ALU_SUB;
//        #10;

//        // ---- SUB test case 2: equal operands (zero flag should assert) ----
//        a = 32'd42;
//        b = 32'd42;
//        alu_ctrl = ALU_SUB;
//        #10;

//        $finish;
//    end

//endmodule

// =============================================================
// alu_tb.v
// Testbench for alu.v - covers normal cases + edge cases
// (overflow wraparound, zero flag, negative operands, boundary values)
// =============================================================

`timescale 1ns/1ps

module alu_tb;

    localparam WIDTH = 32;

    reg  [WIDTH-1:0] a, b;
    reg  [3:0]       alu_ctrl;
    wire [WIDTH-1:0] result;
    wire             zero;

    integer pass_count = 0;
    integer fail_count = 0;

    // control encodings must match alu.v
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;

    alu DUT (
        .i_data_a(a),
        .i_data_b(b),
        .i_alu_control(alu_ctrl),
        .o_result(result),
        .o_zero_flag(zero)
    );

    // ---- helper task to check a test case ----
    task run_test;
        input [8*40-1:0] test_name;  // string label for readability
        input [WIDTH-1:0] in_a;
        input [WIDTH-1:0] in_b;
        input [3:0]        ctrl;
        input [WIDTH-1:0] expected_result;
        input              expected_zero;
        begin
            a = in_a;
            b = in_b;
            alu_ctrl = ctrl;
            #10; // allow combinational logic to settle

            if (result === expected_result && zero === expected_zero) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s | a=%0d b=%0d ctrl=%b -> result=%0d zero=%b",
                          test_name, $signed(in_a), $signed(in_b), ctrl,
                          $signed(result), zero);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s | a=%0d b=%0d ctrl=%b -> got result=%0d zero=%b | expected result=%0d zero=%b",
                          test_name, $signed(in_a), $signed(in_b), ctrl,
                          $signed(result), zero, $signed(expected_result), expected_zero);
            end
        end
    endtask

    initial begin
        $display("---- Starting ALU testbench ----");

        // ---------- Basic ADD cases ----------
        run_test("ADD: simple positive",        32'd10, 32'd20, ALU_ADD, 32'd30, 1'b0);
        run_test("ADD: with zero operand",       32'd0,  32'd15, ALU_ADD, 32'd15, 1'b0);
        run_test("ADD: two negatives",           -32'd5, -32'd7, ALU_ADD, -32'd12, 1'b0);
        run_test("ADD: pos + neg = zero",        32'd25, -32'd25, ALU_ADD, 32'd0, 1'b1);

        // ---------- Basic SUB cases ----------
        run_test("SUB: simple positive",         32'd50, 32'd20, ALU_SUB, 32'd30, 1'b0);
        run_test("SUB: result negative",          32'd10, 32'd20, ALU_SUB, -32'd10, 1'b0);
        run_test("SUB: equal operands (beq true)",32'd42, 32'd42, ALU_SUB, 32'd0, 1'b1);
        run_test("SUB: zero minus zero",          32'd0,  32'd0,  ALU_SUB, 32'd0, 1'b1);

        // ---------- Edge cases: boundary values (two's complement wraparound) ----------
        // Max positive 32-bit signed + 1 -> overflow wraps to min negative
        run_test("ADD: signed overflow wraparound", 32'h7FFFFFFF, 32'd1, ALU_ADD, 32'h80000000, 1'b0);

        // Min negative - 1 -> underflow wraps to max positive
        run_test("SUB: signed underflow wraparound", 32'h80000000, 32'd1, ALU_SUB, 32'h7FFFFFFF, 1'b0);

        // All-ones operand (representation of -1) added to 1 -> zero
        run_test("ADD: -1 + 1 = 0", 32'hFFFFFFFF, 32'd1, ALU_ADD, 32'd0, 1'b1);

        // Max unsigned-looking value subtracted from itself
        run_test("SUB: max value - itself", 32'hFFFFFFFF, 32'hFFFFFFFF, ALU_SUB, 32'd0, 1'b1);

        // Zero minus max value (tests wraparound the other direction)
        run_test("SUB: 0 - max", 32'd0, 32'hFFFFFFFF, ALU_SUB, 32'd1, 1'b0);

        $display("---- Testbench complete: %0d passed, %0d failed ----", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - check log above");

        $finish;
    end

endmodule