`include "config.vh"
`include "opcodes.vh"

// Purely combinational decoder for both PID_Basic instruction formats.
module decoder (
    input  wire [`INSTR_WIDTH-1:0] instruction,
    output reg  [`REG_ADDR_W-1:0]  src_a,
    output reg  [`REG_ADDR_W-1:0]  src_b,
    output reg  [`REG_ADDR_W-1:0]  dest,
    output reg  [`DATA_MSB:0]      immediate_a,
    output reg  [`DATA_MSB:0]      immediate_b,
    output reg                     use_immediate_a,
    output reg                     use_immediate_b,
    output reg  [1:0]              alu_operation,
    output reg                     register_write,
    output reg                     write_immediate,
    output reg                     memory_read,
    output reg                     memory_write,
    output reg  [`ADDR_MSB:0]      memory_address,
    output reg                     jump,
    output reg                     jump_absolute,
    output reg  [`ADDR_MSB:0]      jump_target,
    output reg                     halt
);
    wire type1 = instruction[31];
    wire [`T1_OPCODE_W-1:0] type1_opcode = instruction[30:17];
    wire [`T2_OPCODE_W-1:0] type2_opcode = instruction[30:22];

    always @* begin
        src_a = instruction[15:11];
        src_b = instruction[9:5];
        dest = instruction[4:0];
        immediate_a = {{(`DATA_WIDTH-5){1'b0}}, instruction[15:11]};
        immediate_b = {{(`DATA_WIDTH-5){1'b0}}, instruction[9:5]};
        use_immediate_a = instruction[16];
        use_immediate_b = instruction[10];
        alu_operation = `ALU_ADD;
        register_write = 1'b0;
        write_immediate = 1'b0;
        memory_read = 1'b0;
        memory_write = 1'b0;
        memory_address = instruction[15:0];
        jump = 1'b0;
        jump_absolute = instruction[21];
        jump_target = instruction[15:0];

        // Unsupported encodings stop safely instead of causing uncontrolled
        // writes or execution through uninitialised instruction memory.
        halt = 1'b1;

        if (type1) begin
            case (type1_opcode)
                `T1_ADD: begin
                    alu_operation = `ALU_ADD;
                    register_write = 1'b1;
                    halt = 1'b0;
                end
                `T1_SUB: begin
                    alu_operation = `ALU_SUB;
                    register_write = 1'b1;
                    halt = 1'b0;
                end
                `T1_MUL: begin
                    alu_operation = `ALU_MUL;
                    register_write = 1'b1;
                    halt = 1'b0;
                end
                `T1_SAR: begin
                    alu_operation = `ALU_SAR;
                    register_write = 1'b1;
                    halt = 1'b0;
                end
                default: begin end
            endcase
        end else begin
            // Type 2's register is always in bits [20:16].
            src_a = instruction[20:16];
            dest = instruction[20:16];
            use_immediate_a = 1'b0;
            use_immediate_b = 1'b0;

            case (type2_opcode)
                `T2_LOAD: begin
                    memory_read = 1'b1;
                    register_write = 1'b1;
                    halt = 1'b0;
                end
                `T2_STORE: begin
                    memory_write = 1'b1;
                    halt = 1'b0;
                end
                `T2_JMP: begin
                    // The supplied assembler represents HALT as a relative
                    // JMP with an offset of zero (jump to self).
                    if (!instruction[21] && instruction[15:0] == 16'h0000) begin
                        halt = 1'b1;
                    end else begin
                        jump = 1'b1;
                        halt = 1'b0;
                    end
                end
                `T2_LI: begin
                    immediate_a = {{(`DATA_WIDTH-16){1'b0}},
                                   instruction[15:0]};
                    register_write = 1'b1;
                    write_immediate = 1'b1;
                    halt = 1'b0;
                end
                default: begin end
            endcase
        end
    end
endmodule
