// ============================================================
// Module: control_unit.v
// Project: Single-cycle MIPS processor in Verilog HDL.
// Description: Combinational control unit. Decodes opcode
//   (and funct, for R-type) into every control signal the
//   datapath needs: alu_src, reg_write, reg_dst, mem_to_reg,
//   branch, jump, mem_read, mem_write, and the 4-bit alu_ctrl.
// Author: github.com/Swarangi-Kale
// ============================================================

module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg        alu_src,
    output reg        reg_write,
    output reg        reg_dst,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jump,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [3:0] alu_ctrl
);

    // Opcode values (see project ISA table)
    localparam OP_RTYPE = 6'b000000; // add
    localparam OP_ADDI  = 6'b001000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_J     = 6'b000010;

    // Funct values (only meaningful when opcode == OP_RTYPE)
    localparam FUNCT_ADD = 6'b100000;

    // ALU control encoding (matches alu.v)
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;

    always @(*) begin
        // Safe defaults every cycle -- avoids inferred latches and
        // guarantees a defined (non-x) fallback for any unrecognized
        // opcode, even though don't-care cases below intentionally
        // override some of these to 'x.
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        reg_dst    = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_ctrl   = ALU_ADD;

        case (opcode)

            OP_RTYPE: begin // add
                alu_src    = 1'b0;
                reg_write  = 1'b1;
                reg_dst    = 1'b1;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                case (funct)
                    FUNCT_ADD: alu_ctrl = ALU_ADD;
                    default:   alu_ctrl = ALU_ADD; // only 'add' exists in this ISA today
                endcase
            end

            OP_ADDI: begin
                alu_src    = 1'b1;
                reg_write  = 1'b1;
                reg_dst    = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_ctrl   = ALU_ADD;
            end

            OP_LW: begin
                alu_src    = 1'b1;
                reg_write  = 1'b1;
                reg_dst    = 1'b0;
                mem_to_reg = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                mem_read   = 1'b1;
                mem_write  = 1'b0;
                alu_ctrl   = ALU_ADD;
            end

            OP_SW: begin
                alu_src    = 1'b1;
                reg_write  = 1'b0;
                reg_dst    = 1'bx; // don't-care: sw writes no register
                mem_to_reg = 1'bx; // don't-care: sw writes no register
                branch     = 1'b0;
                jump       = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b1;
                alu_ctrl   = ALU_ADD;
            end

            OP_BEQ: begin
                alu_src    = 1'b0;
                reg_write  = 1'b0;
                reg_dst    = 1'bx; // don't-care: beq writes no register
                mem_to_reg = 1'bx; // don't-care: beq writes no register
                branch     = 1'b1;
                jump       = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_ctrl   = ALU_SUB;
            end

            OP_J: begin
                alu_src    = 1'bx; // don't-care: j doesn't use the ALU
                reg_write  = 1'b0;
                reg_dst    = 1'bx; // don't-care: j writes no register
                mem_to_reg = 1'bx; // don't-care: j writes no register
                branch     = 1'bx;
                jump       = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_ctrl   = 4'bxxxx; // don't-care: ALU output unused for j
            end

            default: begin
                // Unrecognized opcode -- outputs stay at the safe
                // defaults set above (all 0, ALU_ADD).
            end

        endcase
    end

endmodule