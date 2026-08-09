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
    output reg                     load,
    output reg                     store,
    output reg                     push,
    output reg                     pop,
    output reg                     jump,
    output reg                     jump_zero,
    output reg                     jump_not_zero,
    output reg                     jump_less,
    output reg                     jump_greater,
    output reg                     call,
    output reg                     ret,
    output reg                     target_absolute,
    output reg  [`ADDR_MSB:0]      control_target,
    output reg                     halt
);
    wire                    is_type1 = instr[31];
    wire [`T1_OPCODE_W-1:0] type1_opcode = instr[30:17];
    wire [`T2_OPCODE_W-1:0] type2_opcode = instr[30:22];

    always @(*) begin
        // Type 1 defaults and fields.
        rd = instr[4:0];
        rs1 = instr[15:11];
        rs2 = instr[9:5];
        immediate_a = {{(`DATA_WIDTH-5){1'b0}}, instr[15:11]};
        immediate_b = {{(`DATA_WIDTH-5){1'b0}}, instr[9:5]};
        src1_is_imm = 1'b0;
        src2_is_imm = 1'b0;
        alu_operation = `ALU_ADD;
        reg_write_en = 1'b0;

        load = 1'b0;
        store = 1'b0;
        push = 1'b0;
        pop = 1'b0;
        jump = 1'b0;
        jump_zero = 1'b0;
        jump_not_zero = 1'b0;
        jump_less = 1'b0;
        jump_greater = 1'b0;
        call = 1'b0;
        ret = 1'b0;
        target_absolute = 1'b0;
        control_target = instr[15:0];
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
                `T1_CMP: begin
                    // CMP stores rs1-rs2 in the dedicated condition register.
                    rd = 5'd5;
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
            // Type 2: [21] selects absolute (1) versus relative/SP-relative
            // (0), [20:16] is the data register, [15:0] is target/offset.
            target_absolute = instr[21];
            case (type2_opcode)
                `T2_LOAD: begin
                    rd = instr[20:16];
                    load = 1'b1;
                end
                `T2_STORE: begin
                    rs1 = instr[20:16];
                    store = 1'b1;
                end
                `T2_JMP: begin
                    jump = 1'b1;
                    halt = !instr[21] && (instr[15:0] == 16'h0000);
                end
                `T2_JZ:  jump_zero = 1'b1;
                `T2_JNZ: jump_not_zero = 1'b1;
                `T2_JLT: jump_less = 1'b1;
                `T2_JGT: jump_greater = 1'b1;
                `T2_CALL: call = 1'b1;
                `T2_RET: ret = 1'b1;
                `T2_PUSH: begin
                    rs1 = instr[20:16];
                    push = 1'b1;
                end
                `T2_POP: begin
                    rd = instr[20:16];
                    pop = 1'b1;
                end
                `T2_LI: begin
                    rd = instr[20:16];
                    immediate_a = {{(`DATA_WIDTH-16){1'b0}}, instr[15:0]};
                    src1_is_imm = 1'b1;
                    alu_operation = `ALU_MOV;
                    reg_write_en = 1'b1;
                end
                default: begin
                    reg_write_en = 1'b0;
                end
            endcase
        end
    end
endmodule
