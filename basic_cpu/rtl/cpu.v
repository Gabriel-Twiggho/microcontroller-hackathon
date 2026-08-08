`include "config.vh"

module cpu (
    input  wire clk,
    input  wire rst,
    output reg  halt,
    output wire [`ADDR_WIDTH-1:0] dbg_pc
);
    reg [`ADDR_WIDTH-1:0] pc;
    wire [`INSTR_WIDTH-1:0] instruction;
    wire [`REG_ADDR_W-1:0] src_a, src_b, dest;
    wire [`DATA_WIDTH-1:0] immediate, read_a, read_b, operand_a, operand_b, alu_result;
    wire [`DATA_WIDTH-1:0] write_data;
    wire [`REG_ADDR_W-1:0] write_addr;
    wire [`ADDR_WIDTH-1:0] control_target;
    wire [`ADDR_WIDTH-1:0] return_address;
    wire use_imm_a, use_imm_b, write_enable, decoded_halt;
    wire call, ret, target_absolute;
    wire effective_write_enable;
    wire [1:0] alu_operation;

    imem u_imem (.address(pc), .instruction(instruction));
    decoder u_decoder (
        .instruction(instruction), .src_a(src_a), .src_b(src_b), .dest(dest),
        .immediate(immediate), .use_imm_a(use_imm_a), .use_imm_b(use_imm_b),
        .alu_operation(alu_operation), .write_enable(write_enable),
        .call(call), .ret(ret), .target_absolute(target_absolute),
        .control_target(control_target), .halt(decoded_halt));
    assign effective_write_enable = (write_enable || call) && !halt && !decoded_halt;
    assign write_addr = call ? 5'd3 : dest;
    assign return_address = pc + 1'b1;
    assign write_data = call ?
        {{(`DATA_WIDTH-`ADDR_WIDTH){1'b0}}, return_address} : alu_result;
    regfile u_regfile (
        .clk(clk), .rst(rst), .read_addr_a(src_a), .read_addr_b(src_b),
        .read_data_a(read_a), .read_data_b(read_b),
        .write_enable(effective_write_enable),
        .write_addr(write_addr), .write_data(write_data));
    assign operand_a = use_imm_a ? immediate : read_a;
    assign operand_b = use_imm_b ? {{27{1'b0}}, src_b} : read_b;
    alu u_alu (.operation(alu_operation), .a(operand_a), .b(operand_b), .result(alu_result));

    always @(posedge clk) begin
        if (rst) begin
            pc <= `PC_INIT;
            halt <= 0;
        end else if (!halt) begin
            if (decoded_halt)
                halt <= 1;
            else if (call)
                pc <= target_absolute ? control_target
                                      : pc + $signed(control_target);
            else if (ret)
                pc <= read_a[`ADDR_WIDTH-1:0];
            else
                pc <= pc + 1'b1;
        end
    end
    assign dbg_pc = pc;
endmodule
