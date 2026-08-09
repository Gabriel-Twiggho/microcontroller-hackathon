`include "config.vh"

// Single-cycle PID_Basic CPU:
// fetch -> decode -> register read -> execute/memory -> register write-back.
module cpu (
    input  wire                 clk,
    input  wire                 rst_n,
    output wire [`ADDR_MSB:0]   dbg_pc,
    output wire                 dbg_halt,
    output wire [`DATA_MSB:0]   dbg_write_data
);
    reg [`ADDR_MSB:0] pc;
    reg halt_state;
    wire [`INSTR_WIDTH-1:0] instr;

    imem u_imem (
        .address(pc),
        .instruction(instr)
    );

    wire [`REG_ADDR_W-1:0] src_a;
    wire [`REG_ADDR_W-1:0] src_b;
    wire [`REG_ADDR_W-1:0] dest;
    wire [`DATA_MSB:0] immediate_a;
    wire [`DATA_MSB:0] immediate_b;
    wire use_immediate_a;
    wire use_immediate_b;
    wire [1:0] alu_operation;
    wire register_write;
    wire write_immediate;
    wire memory_read;
    wire memory_write;
    wire [`ADDR_MSB:0] memory_address;
    wire jump;
    wire jump_absolute;
    wire [`ADDR_MSB:0] jump_target;
    wire decoded_halt;

    decoder u_decoder (
        .instruction(instr),
        .src_a(src_a),
        .src_b(src_b),
        .dest(dest),
        .immediate_a(immediate_a),
        .immediate_b(immediate_b),
        .use_immediate_a(use_immediate_a),
        .use_immediate_b(use_immediate_b),
        .alu_operation(alu_operation),
        .register_write(register_write),
        .write_immediate(write_immediate),
        .memory_read(memory_read),
        .memory_write(memory_write),
        .memory_address(memory_address),
        .jump(jump),
        .jump_absolute(jump_absolute),
        .jump_target(jump_target),
        .halt(decoded_halt)
    );

    wire [`DATA_MSB:0] read_a;
    wire [`DATA_MSB:0] read_b;
    wire [`DATA_MSB:0] write_data;
    wire effective_register_write = register_write && !halt_state &&
                                    !decoded_halt;

    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .read_addr_a(src_a),
        .read_addr_b(src_b),
        .read_data_a(read_a),
        .read_data_b(read_b),
        .write_enable(effective_register_write),
        .write_addr(dest),
        .write_data(write_data)
    );

    wire [`DATA_MSB:0] operand_a = use_immediate_a ? immediate_a : read_a;
    wire [`DATA_MSB:0] operand_b = use_immediate_b ? immediate_b : read_b;
    wire [`DATA_MSB:0] alu_result;

    alu u_alu (
        .a(operand_a),
        .b(operand_b),
        .operation(alu_operation),
        .result(alu_result)
    );

    wire [`DATA_MSB:0] memory_read_data;
    wire effective_memory_write = memory_write && !halt_state &&
                                  !decoded_halt;

    dmem u_dmem (
        .clk(clk),
        .write_enable(effective_memory_write),
        .address(memory_address),
        .write_data(read_a),
        .read_data(memory_read_data)
    );

    assign write_data = memory_read ? memory_read_data :
                        write_immediate ? immediate_a : alu_result;

    always @(posedge clk) begin
        if (!rst_n) begin
            pc <= `PC_INIT;
            halt_state <= 1'b0;
        end else if (!halt_state) begin
            if (decoded_halt) begin
                halt_state <= 1'b1;
            end else if (jump) begin
                if (jump_absolute)
                    pc <= jump_target;
                else
                    pc <= pc + $signed(jump_target);
            end else begin
                pc <= pc + 1'b1;
            end
        end
    end

    assign dbg_pc = pc;
    assign dbg_halt = halt_state;
    assign dbg_write_data = write_data;
endmodule
