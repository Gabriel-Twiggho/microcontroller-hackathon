`include "config.vh"
`include "opcodes.vh"

module decoder (
    input  wire [`INSTR_WIDTH-1:0] instruction,
    output reg  [`REG_ADDR_W-1:0]  src_a,
    output reg  [`REG_ADDR_W-1:0]  src_b,
    output reg  [`REG_ADDR_W-1:0]  dest,
    output reg  [`DATA_WIDTH-1:0]  immediate,
    output reg                      use_imm_a,
    output reg                      use_imm_b,
    output reg  [1:0]               alu_operation,
    output reg                      write_enable,
    output reg                      call,
    output reg                      ret,
    output reg                      target_absolute,
    output reg  [`ADDR_WIDTH-1:0]   control_target,
    output reg                      halt
);
    wire type1 = instruction[31];
    wire [13:0] opcode1 = instruction[30:17];
    wire [8:0]  opcode2 = instruction[30:22];

    always @* begin
        src_a = instruction[15:11];
        src_b = instruction[9:5];
        dest = instruction[4:0];
        // Type 1's inline immediate is arg2[4:0]. Type 2 LI replaces this
        // with its full 16-bit payload below.
        immediate = {27'b0, instruction[9:5]};
        use_imm_a = instruction[16];
        use_imm_b = instruction[10];
        alu_operation = `ALU_ADD;
        write_enable = 0;
        call = 0;
        ret = 0;
        target_absolute = 0;
        control_target = instruction[15:0];
        halt = 0;

        if (type1) begin
            case (opcode1)
                `T1_ADD: begin alu_operation = `ALU_ADD; write_enable = 1; end
                `T1_SUB: begin alu_operation = `ALU_SUB; write_enable = 1; end
                `T1_MOV: begin
                    alu_operation = `ALU_MOV;
                    write_enable = 1;
                    use_imm_a = instruction[16];
                    use_imm_b = 0;
                end
                default: halt = 1; // Fail safely on an unsupported instruction.
            endcase
        end else begin
            case (opcode2)
                `T2_LI: begin
                    dest = instruction[20:16];
                    immediate = {16'b0, instruction[15:0]};
                    use_imm_a = 1;
                    use_imm_b = 0;
                    alu_operation = `ALU_MOV;
                    write_enable = 1;
                end
                // asm.py encodes HALT as JMP #0.
                `T2_JMP: halt = (instruction[21] == 0 && instruction[15:0] == 0);
                `T2_CALL: begin
                    call = 1;
                    target_absolute = instruction[21];
                end
                `T2_RET: begin
                    ret = 1;
                    src_a = 5'd3; // r3 is the leaf-function link register.
                end
                default: halt = 1;
            endcase
        end
    end
endmodule
