`include "config.vh"
`include "opcodes.vh"

module decoder (
    input  wire [`INSTR_WIDTH-1:0] instr,
    output reg  [`REG_ADDR_W-1:0]  rd,
    output reg  [`REG_ADDR_W-1:0]  rs1,
    output reg  [`REG_ADDR_W-1:0]  rs2,
    output reg  [`DATA_MSB:0]      immediate_a,
    output reg  [`DATA_MSB:0]      immediate_b,
    output reg                     src1_is_imm,
    output reg                     src2_is_imm,
    output reg  [`ALU_OP_W-1:0]    alu_operation,
    output reg                     reg_write_en,
    output reg                     halt
);
    wire                         is_type1 = instr[31];
    wire [`T1_OPCODE_W-1:0]      type1_opcode = instr[30:17];
    wire [`T2_OPCODE_W-1:0]      type2_opcode = instr[30:22];

    always @(*) begin
        // Type 1 field locations:
        // [16] arg1 immediate flag, [15:11] arg1 value,
        // [10] arg2 immediate flag, [9:5] arg2 value, [4:0] result.
        rd = instr[4:0];
        rs1 = instr[15:11];
        rs2 = instr[9:5];
        immediate_a = {{(`DATA_WIDTH-5){1'b0}}, instr[15:11]};
        immediate_b = {{(`DATA_WIDTH-5){1'b0}}, instr[9:5]};
        src1_is_imm = 1'b0;
        src2_is_imm = 1'b0;
        alu_operation = `ALU_ADD;
        reg_write_en = 1'b0;
        halt = 1'b0;

        if (is_type1) begin
            src1_is_imm = instr[16];
            src2_is_imm = instr[10];

            case (type1_opcode)
                `T1_ADD: begin
                    alu_operation = `ALU_ADD;
                    reg_write_en = 1'b1;
                end
                `T1_SUB: begin
                    alu_operation = `ALU_SUB;
                    reg_write_en = 1'b1;
                end
                `T1_MOV: begin
                    alu_operation = `ALU_MOV;
                    reg_write_en = 1'b1;
                end
                default: begin
                    reg_write_en = 1'b0;
                end
            endcase
        end else begin
            // Type 2 layout: [21] register/immediate selector,
            // [20:16] register, [15:0] address/immediate.
            case (type2_opcode)
                `T2_LI: begin
                    rd = instr[20:16];
                    immediate_a = {{(`DATA_WIDTH-16){1'b0}}, instr[15:0]};
                    src1_is_imm = 1'b1;
                    alu_operation = `ALU_MOV;
                    reg_write_en = 1'b1;
                end
                // The assembler represents HALT as the relative JMP #0
                // pseudo-instruction. Other jumps belong to Stage 2.
                `T2_JMP: begin
                    halt = (instr[21] == 1'b0) && (instr[15:0] == 16'h0000);
                end
                default: begin
                    reg_write_en = 1'b0;
                end
            endcase
        end

    end
endmodule
