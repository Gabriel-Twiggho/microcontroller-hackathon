`include "config.vh"
`include "opcodes.vh"

module cpu (
    input  wire clk,
    input  wire rst_n,
    output wire [`ADDR_MSB:0] dbg_pc,
    output wire                dbg_halt
);

// --- Program Counter ---------------------------------------------------
// No conditional branches yet (Stage 2): PC either advances by one
// instruction, or redirects for CALL/RET (see the PC-next mux below).
reg [`ADDR_MSB:0] pc;
wire [`ADDR_MSB:0] pc_next;

assign dbg_pc = pc;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) pc <= `PC_INIT;
    else        pc <= pc_next;
end

// --- Instruction Fetch ---------------------------------------------------
wire [`INSTR_WIDTH-1:0] instr;
imem #(.DEPTH(`IMEM_DEPTH)) u_imem (.addr(pc), .data(instr));

// --- Decode ---------------------------------------------------------------
wire is_type1, is_alu_op, is_li, is_call, is_ret, is_halt;
wire [`OPCODE_W-1:0]    t1_opcode;
wire [`REG_ADDR_W-1:0]  rd;
wire                    arg1_imm, arg2_imm;
wire [`REG_ADDR_W-1:0]  arg1_val, arg2_val;
wire [`T2_OPCODE_W-1:0] t2_opcode;
wire [`T2_ADDR_W-1:0]   t2_addr;
wire                    reg_write_en;

decoder u_decoder (
    .instr(instr),
    .is_type1(is_type1),
    .is_alu_op(is_alu_op),
    .is_li(is_li),
    .is_call(is_call),
    .is_ret(is_ret),
    .is_halt(is_halt),
    .t1_opcode(t1_opcode),
    .rd(rd),
    .arg1_imm(arg1_imm),
    .arg1_val(arg1_val),
    .arg2_imm(arg2_imm),
    .arg2_val(arg2_val),
    .t2_opcode(t2_opcode),
    .t2_addr(t2_addr),
    .reg_write_en(reg_write_en)
);

assign dbg_halt = is_halt;

// --- Register File --------------------------------------------------------
wire [`DATA_MSB:0] rdata_a, rdata_b;
reg  [`DATA_MSB:0] wb_data;

// RET has no operand fields (asm.py encodes it as all-zero) — it always
// targets the link register (r3), so port A is repurposed to read it.
wire [`REG_ADDR_W-1:0] rd_addr_a = is_ret ? `LR_REG : arg1_val;

// CALL writes PC+1 into r3, overriding the decoded `rd` (which is 0 for
// CALL, per asm.py's encoding — the link register is architecturally
// fixed, not operand-selected).
wire [`REG_ADDR_W-1:0] wr_addr = is_call ? `LR_REG : rd;

regfile u_regfile (
    .clk(clk),
    .wr_en(reg_write_en),
    .wr_addr(wr_addr),
    .wr_data(wb_data),
    .rd_addr_a(rd_addr_a),
    .rd_addr_b(arg2_val),
    .rd_data_a(rdata_a),
    .rd_data_b(rdata_b)
);

// --- Operand mux: register value or zero-extended 5-bit immediate ---------
wire [`DATA_MSB:0] operand_a = arg1_imm ? {{(`DATA_WIDTH-`REG_ADDR_W){1'b0}}, arg1_val} : rdata_a;
wire [`DATA_MSB:0] operand_b = arg2_imm ? {{(`DATA_WIDTH-`REG_ADDR_W){1'b0}}, arg2_val} : rdata_b;

// --- ALU --------------------------------------------------------------------
wire [`DATA_MSB:0] alu_result;
alu u_alu (
    .a(operand_a),
    .b(operand_b),
    .opcode(t1_opcode),
    .result(alu_result)
);

// --- Write-back mux ----------------------------------------------------------
wire [`DATA_MSB:0] li_value = {{(`DATA_WIDTH-`T2_ADDR_W){1'b0}}, t2_addr};
wire [`DATA_MSB:0] return_addr = {{(`DATA_WIDTH-`ADDR_WIDTH){1'b0}}, pc + 1'b1};

always @(*) begin
    if (is_alu_op)
        wb_data = alu_result;
    else if (is_li)
        wb_data = li_value;
    else if (is_call)
        wb_data = return_addr;
    else
        wb_data = {`DATA_WIDTH{1'b0}};
end

// --- PC-next mux ---------------------------------------------------------
// CALL: PC-relative redirect using the CALL instruction's own address
// (matches tools/asm.py's `offset = labels[target] - pc`, where pc is the
// CALL instruction's own address, not pc+1 — the same convention used by
// the HALT sentinel above).
// RET: redirect to the address held in the link register (read via
// rd_addr_a/rdata_a, repurposed above).
wire signed [`T2_ADDR_W-1:0] call_offset = t2_addr;
wire [`ADDR_MSB:0] call_target = pc + call_offset[`ADDR_MSB:0];
wire [`ADDR_MSB:0] ret_target  = rdata_a[`ADDR_MSB:0];

assign pc_next = is_ret  ? ret_target  :
                  is_call ? call_target :
                             pc + 1'b1;

endmodule
