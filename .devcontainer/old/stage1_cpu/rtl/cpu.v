`include "config.vh"
`include "opcodes.vh"

module cpu (
    input  wire               clk,
    input  wire               rst_n,
    output wire [`ADDR_MSB:0] dbg_pc,
    output wire               dbg_halt
);
    reg [`ADDR_MSB:0] pc;
    wire [`INSTR_WIDTH-1:0] instr;

    imem #(.DEPTH(`IMEM_DEPTH)) u_imem (
        .addr(pc),
        .data(instr)
    );

    wire [`REG_ADDR_W-1:0] rd;
    wire [`REG_ADDR_W-1:0] rs1;
    wire [`REG_ADDR_W-1:0] rs2;
    wire [`DATA_MSB:0] immediate_a;
    wire [`DATA_MSB:0] immediate_b;
    wire src1_is_imm;
    wire src2_is_imm;
    wire [`ALU_OP_W-1:0] alu_operation;
    wire reg_write_en;
    wire load, store, push, pop;
    wire jump, jump_zero, jump_not_zero, jump_less, jump_greater;
    wire call, ret, target_absolute;
    wire [`ADDR_MSB:0] control_target;
    wire halt;

    decoder u_decoder (
        .instr(instr),
        .rd(rd), .rs1(rs1), .rs2(rs2),
        .immediate_a(immediate_a), .immediate_b(immediate_b),
        .src1_is_imm(src1_is_imm), .src2_is_imm(src2_is_imm),
        .alu_operation(alu_operation), .reg_write_en(reg_write_en),
        .load(load), .store(store), .push(push), .pop(pop),
        .jump(jump), .jump_zero(jump_zero),
        .jump_not_zero(jump_not_zero), .jump_less(jump_less),
        .jump_greater(jump_greater), .call(call), .ret(ret),
        .target_absolute(target_absolute), .control_target(control_target),
        .halt(halt)
    );

    wire [`DATA_MSB:0] reg_a;
    wire [`DATA_MSB:0] reg_b;
    wire [`DATA_MSB:0] sp_value;
    wire [`DATA_MSB:0] link_value;
    wire [`DATA_MSB:0] condition_value;
    wire [`DATA_MSB:0] alu_result;
    wire [`DATA_MSB:0] regfile_write_data;
    wire [`REG_ADDR_W-1:0] regfile_write_addr;
    wire regfile_write_enable;
    wire sp_write_enable = push || pop;
    wire [`DATA_MSB:0] sp_write_data = push
        ? sp_value - `WORD_BYTES
        : sp_value + `WORD_BYTES;
    wire [`ADDR_MSB:0] return_address = pc + 1'b1;

    wire [`DATA_MSB:0] operand_a = src1_is_imm ? immediate_a : reg_a;
    wire [`DATA_MSB:0] operand_b = src2_is_imm ? immediate_b : reg_b;

    alu u_alu (
        .operation(alu_operation),
        .a(operand_a),
        .b(operand_b),
        .result(alu_result)
    );

    // Absolute memory operands use the 16-bit address directly. Register
    // indirect operands are SP-relative; asm.py encodes their signed offset in
    // the address field and their load/store data register in [20:16].
    wire [`ADDR_MSB:0] sp_relative_address =
        sp_value[`ADDR_MSB:0] + $signed(control_target);
    wire [`ADDR_MSB:0] memory_address = push
        ? (sp_value[`ADDR_MSB:0] - `WORD_BYTES)
        : pop
            ? sp_value[`ADDR_MSB:0]
            : target_absolute ? control_target : sp_relative_address;
    wire [`DATA_MSB:0] memory_read_data;

    dmem #(.DEPTH(`DMEM_DEPTH)) u_dmem (
        .clk(clk),
        .wr_en(store || push),
        .addr(memory_address),
        .wr_data(reg_a),
        .rd_data(memory_read_data)
    );

    assign regfile_write_addr = call ? 5'd3 : rd;
    assign regfile_write_data = call
        ? {{(`DATA_WIDTH-`ADDR_WIDTH){1'b0}}, return_address}
        : (load || pop) ? memory_read_data : alu_result;
    assign regfile_write_enable = (reg_write_en || load || pop || call) && !halt;

    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(regfile_write_enable),
        .wr_addr(regfile_write_addr),
        .wr_data(regfile_write_data),
        .sp_wr_en(sp_write_enable),
        .sp_wr_data(sp_write_data),
        .rd_addr_a(rs1),
        .rd_addr_b(rs2),
        .rd_data_a(reg_a),
        .rd_data_b(reg_b),
        .sp_data(sp_value),
        .link_data(link_value),
        .condition_data(condition_value)
    );

    wire [`ADDR_MSB:0] pc_next;
    wire branch_taken;

    branch u_branch (
        .pc_current(pc),
        .condition(condition_value),
        .link_value(link_value),
        .target_field(control_target),
        .target_absolute(target_absolute),
        .jump(jump),
        .jump_zero(jump_zero),
        .jump_not_zero(jump_not_zero),
        .jump_less(jump_less),
        .jump_greater(jump_greater),
        .call(call),
        .ret(ret),
        .pc_next(pc_next),
        .branch_taken(branch_taken)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= `PC_INIT;
        else
            pc <= pc_next;
    end

    assign dbg_pc = pc;
    assign dbg_halt = halt && branch_taken && (pc_next == pc);
endmodule
