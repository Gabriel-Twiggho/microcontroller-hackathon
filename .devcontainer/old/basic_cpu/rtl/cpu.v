`include "config.vh"

// Single-cycle CPU template.
//
// This follows the workbook's Stage 1 datapath:
//   fetch -> decode -> register read -> operand select -> ALU -> write-back
// The small CALL/RET additions use r3 as the link register, while HALT is
// assembled as JMP #0 and is recognized by decoder.v.
module cpu (
    input  wire                  clk,
    input  wire                  rst,
    output reg                   halt,
    output wire [`ADDR_WIDTH-1:0] dbg_pc
);
    // ── Program counter and instruction fetch ─────────────────────
    reg  [`ADDR_WIDTH-1:0] pc;
    wire [`INSTR_WIDTH-1:0] instruction;

    imem u_imem (
        .address(pc),
        .instruction(instruction)
    );

    // ── Decode ────────────────────────────────────────────────────
    wire [`REG_ADDR_W-1:0] src_a;
    wire [`REG_ADDR_W-1:0] src_b;
    wire [`REG_ADDR_W-1:0] dest;
    wire [`DATA_WIDTH-1:0] immediate;
    wire                    use_imm_a;
    wire                    use_imm_b;
    wire [1:0]              alu_operation;
    wire                    write_enable;
    wire                    call;
    wire                    ret;
    wire                    target_absolute;
    wire [`ADDR_WIDTH-1:0] control_target;
    wire                    decoded_halt;

    decoder u_decoder (
        .instruction(instruction),
        .src_a(src_a),
        .src_b(src_b),
        .dest(dest),
        .immediate(immediate),
        .use_imm_a(use_imm_a),
        .use_imm_b(use_imm_b),
        .alu_operation(alu_operation),
        .write_enable(write_enable),
        .call(call),
        .ret(ret),
        .target_absolute(target_absolute),
        .control_target(control_target),
        .halt(decoded_halt)
    );

    // ── Register read ─────────────────────────────────────────────
    wire [`DATA_WIDTH-1:0] read_a;
    wire [`DATA_WIDTH-1:0] read_b;
    wire [`REG_ADDR_W-1:0] write_addr;
    wire [`DATA_WIDTH-1:0] write_data;
    wire                    effective_write_enable;

    regfile u_regfile (
        .clk(clk),
        .rst(rst),
        .read_addr_a(src_a),
        .read_addr_b(src_b),
        .read_data_a(read_a),
        .read_data_b(read_b),
        .write_enable(effective_write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    // ── Operand select and execute ─────────────────────────────────
    // Type-1 immediates occupy the same five-bit field as src_b.  The
    // decoder zero-extends them; LI supplies its full 16-bit immediate.
    wire [`DATA_WIDTH-1:0] operand_a = use_imm_a ? immediate : read_a;
    wire [`DATA_WIDTH-1:0] operand_b = use_imm_b
        ? {{(`DATA_WIDTH-`REG_ADDR_W){1'b0}}, src_b}
        : read_b;
    wire [`DATA_WIDTH-1:0] alu_result;

    alu u_alu (
        .operation(alu_operation),
        .a(operand_a),
        .b(operand_b),
        .result(alu_result)
    );

    // ── Write-back ─────────────────────────────────────────────────
    // CALL writes the address of the following instruction to r3.  Every
    // ordinary arithmetic/LI instruction writes the ALU result to dest.
    wire [`ADDR_WIDTH-1:0] return_address = pc + 1'b1;
    assign write_addr = call ? 5'd3 : dest;
    assign write_data = call
        ? {{(`DATA_WIDTH-`ADDR_WIDTH){1'b0}}, return_address}
        : alu_result;
    assign effective_write_enable = (write_enable || call) && !halt && !decoded_halt;

    // ── Next-PC and halt ───────────────────────────────────────────
    // Normal execution advances one word because instruction memory is
    // word-addressed.  Relative CALL targets are signed word offsets.
    always @(posedge clk) begin
        if (rst) begin
            pc   <= `PC_INIT;
            halt <= 1'b0;
        end else if (!halt) begin
            if (decoded_halt)
                halt <= 1'b1;
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
