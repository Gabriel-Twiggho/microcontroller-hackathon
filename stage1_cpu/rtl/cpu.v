`include "config.vh"
`include "opcodes.vh"

module cpu (
    input  wire               clk,
    input  wire               rst_n,
    output wire [`ADDR_MSB:0] dbg_pc,
    output wire               dbg_halt
);
    // Fetch: Stage 1 executes one complete instruction per clock cycle.
    reg [`ADDR_MSB:0] pc;
    wire [`INSTR_WIDTH-1:0] instr;

    imem #(.DEPTH(`IMEM_DEPTH)) u_imem (
        .addr(pc),
        .data(instr)
    );

    // Decode.
    wire [`REG_ADDR_W-1:0] rd;
    wire [`REG_ADDR_W-1:0] rs1;
    wire [`REG_ADDR_W-1:0] rs2;
    wire [`DATA_MSB:0] immediate_a;
    wire [`DATA_MSB:0] immediate_b;
    wire src1_is_imm;
    wire src2_is_imm;
    wire [`ALU_OP_W-1:0] alu_operation;
    wire reg_write_en;
    wire halt;

    decoder u_decoder (
        .instr(instr),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .immediate_a(immediate_a),
        .immediate_b(immediate_b),
        .src1_is_imm(src1_is_imm),
        .src2_is_imm(src2_is_imm),
        .alu_operation(alu_operation),
        .reg_write_en(reg_write_en),
        .halt(halt)
    );

    // Register operands and synchronous write-back.
    wire [`DATA_MSB:0] reg_a;
    wire [`DATA_MSB:0] reg_b;
    wire [`DATA_MSB:0] writeback_data;

    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(reg_write_en && !halt),
        .wr_addr(rd),
        .wr_data(writeback_data),
        .rd_addr_a(rs1),
        .rd_addr_b(rs2),
        .rd_data_a(reg_a),
        .rd_data_b(reg_b)
    );

    // Execute: each Type 1 operand may independently be a register or a
    // zero-extended five-bit immediate. LI routes its 16-bit immediate to A.
    wire [`DATA_MSB:0] operand_a = src1_is_imm ? immediate_a : reg_a;
    wire [`DATA_MSB:0] operand_b = src2_is_imm ? immediate_b : reg_b;

    alu u_alu (
        .operation(alu_operation),
        .a(operand_a),
        .b(operand_b),
        .result(writeback_data)
    );

    // Stage 1 has only sequential PC movement. HALT freezes the PC.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= `PC_INIT;
        else if (!halt)
            pc <= pc + 1'b1;
    end

    assign dbg_pc = pc;
    assign dbg_halt = halt;
endmodule
