`include "config.vh"
`include "opcodes.vh"

// Purely combinational instruction decoder.
//
// Type 1 (ALU, instr[31]=1): [30:17]=opcode [16]=arg1_imm [15:11]=arg1_val
//                             [10]=arg2_imm [9:5]=arg2_val [4:0]=rd
// Type 2 (Mem/Control, instr[31]=0): [30:22]=opcode [21]=ri [20:16]=reg
//                             [15:0]=addr
//
// HALT is not a real opcode: asm.py encodes the HALT pseudo as "JMP to
// self" with every Type 2 field zero, so is_halt just recognises that
// specific bit pattern.
module decoder (
    input  wire [`INSTR_WIDTH-1:0]   instr,

    output wire                      is_type1,
    output wire                      is_alu_op,
    output wire                      is_li,
    output wire                      is_call,
    output wire                      is_ret,
    output wire                      is_halt,

    output wire [`OPCODE_W-1:0]      t1_opcode,
    output wire [`REG_ADDR_W-1:0]    rd,
    output wire                      arg1_imm,
    output wire [`REG_ADDR_W-1:0]    arg1_val,
    output wire                      arg2_imm,
    output wire [`REG_ADDR_W-1:0]    arg2_val,

    output wire [`T2_OPCODE_W-1:0]   t2_opcode,
    output wire [`T2_ADDR_W-1:0]     t2_addr,

    output wire                      reg_write_en
);

assign is_type1 = instr[31];

// Type 1 fields
assign t1_opcode = instr[30:17]; 
assign arg1_imm  = instr[16]; 
assign arg1_val  = instr[15:11];
assign arg2_imm  = instr[10];
assign arg2_val  = instr[9:5];
wire [`REG_ADDR_W-1:0] t1_rd = instr[4:0];

// Type 2 fields
assign t2_opcode = instr[30:22];
wire [`REG_ADDR_W-1:0] t2_reg = instr[20:16];
assign t2_addr   = instr[15:0];

assign rd = is_type1 ? t1_rd : t2_reg;

assign is_alu_op = is_type1 &&
    ((t1_opcode == `OP_ADD) || (t1_opcode == `OP_SUB) || (t1_opcode == `OP_MOV));
assign is_li   = !is_type1 && (t2_opcode == `OP_LI);
assign is_call = !is_type1 && (t2_opcode == `OP_CALL);
assign is_ret  = !is_type1 && (t2_opcode == `OP_RET);

// HALT sentinel: Type 2, opcode==JMP, ri/reg/addr all zero (instr[21:0]==0).
assign is_halt = !is_type1 && (t2_opcode == `OP_JMP) && (instr[21:0] == 22'b0);

// CALL writes PC+1 into the link register (r3), not the decoded `rd` field.
assign reg_write_en = is_alu_op || is_li || is_call;

endmodule
