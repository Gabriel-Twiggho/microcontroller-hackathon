`include "config.vh"
`include "opcodes.vh"

// Reworked minimum CPU: 16-bit instructions, eight 16-bit registers and a
// two-cycle LOAD so the data memory maps to synchronous FPGA block RAM.
module cpu (
    input wire clk,
    input wire rst_n,
    output wire [5:0] dbg_pc,
    output wire dbg_halt,
    output wire [`DATA_MSB:0] dbg_write_data
);
    reg [5:0] pc;
    reg halt_state;
    reg load_pending;
    reg [`REG_ADDR_W-1:0] load_dest;
`ifdef TINY_HAS_CMP
    reg flag_zero;
    reg flag_less;
    reg flag_greater;
`endif

    wire [`INSTR_WIDTH-1:0] instr;
    wire [3:0] opcode = instr[15:12];
    wire [`REG_ADDR_W-1:0] rd = instr[11:9];
    wire [`REG_ADDR_W-1:0] ra = instr[8:6];
    wire [`REG_ADDR_W-1:0] rb = instr[5:3];
    wire [`ADDR_MSB:0] address = instr[8:0];
    wire signed [11:0] branch_offset = instr[11:0];

    imem u_imem (.address(pc), .instruction(instr));

    wire [`DATA_MSB:0] read_a;
    wire [`DATA_MSB:0] read_b;
    reg [`DATA_MSB:0] execute_result;
    reg execute_write;
    reg decoded_valid;
    reg branch_taken;

    wire load_write = load_pending && !halt_state;
    wire reg_write = load_write || (execute_write && !halt_state);
    wire [`REG_ADDR_W-1:0] reg_write_addr = load_write ? load_dest : rd;
    wire [`DATA_MSB:0] memory_read_data;
    wire [`DATA_MSB:0] reg_write_data = load_write ? memory_read_data : execute_result;

    wire [`REG_ADDR_W-1:0] read_addr_a =
        (opcode == `OP_STORE) ? rd : ra;

    regfile u_regfile (
        .clk(clk), .rst_n(rst_n),
        .read_addr_a(read_addr_a), .read_addr_b(rb),
        .read_data_a(read_a), .read_data_b(read_b),
        .write_enable(reg_write), .write_addr(reg_write_addr),
        .write_data(reg_write_data)
    );

    wire memory_store = (opcode == `OP_STORE) && !load_pending &&
                        !halt_state;
    dmem u_dmem (
        .clk(clk), .write_enable(memory_store), .address(address),
        .write_data(read_a), .read_data(memory_read_data)
    );

    always @* begin
        execute_result = 16'h0000;
        execute_write = 1'b0;
        decoded_valid = 1'b1;
        branch_taken = 1'b0;
        case (opcode)
            `OP_ADD: begin execute_result = read_a + read_b; execute_write = 1'b1; end
            `OP_SUB: begin execute_result = read_a - read_b; execute_write = 1'b1; end
            `OP_MUL: begin execute_result = read_a * read_b; execute_write = 1'b1; end
            `OP_LOAD: begin end
            `OP_STORE: begin end
            `OP_LI: begin execute_result = {7'b0, instr[8:0]}; execute_write = 1'b1; end
            `OP_JMP: branch_taken = 1'b1;
`ifdef TINY_HAS_SAR
            `OP_SAR: begin
                execute_result = $signed(read_a) >>> instr[5:3];
                execute_write = 1'b1;
            end
`endif
`ifdef TINY_HAS_CMP
            `OP_CMP: begin end
            `OP_JZ:  branch_taken = flag_zero;
            `OP_JNZ: branch_taken = !flag_zero;
            `OP_JLT: branch_taken = flag_less;
            `OP_JGT: branch_taken = flag_greater;
`endif
            `OP_HALT: begin end
            default: decoded_valid = 1'b0;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            pc <= 6'd0;
            halt_state <= 1'b0;
            load_pending <= 1'b0;
            load_dest <= 3'd0;
`ifdef TINY_HAS_CMP
            flag_zero <= 1'b0;
            flag_less <= 1'b0;
            flag_greater <= 1'b0;
`endif
        end else if (!halt_state) begin
            if (load_pending) begin
                load_pending <= 1'b0;
                pc <= pc + 1'b1;
            end else if (!decoded_valid || opcode == `OP_HALT) begin
                halt_state <= 1'b1;
            end else if (opcode == `OP_LOAD) begin
                load_pending <= 1'b1;
                load_dest <= rd;
            end else begin
`ifdef TINY_HAS_CMP
                if (opcode == `OP_CMP) begin
                    flag_zero <= (read_a == read_b);
                    flag_less <= ($signed(read_a) < $signed(read_b));
                    flag_greater <= ($signed(read_a) > $signed(read_b));
                end
`endif
                if (branch_taken)
                    // The 64-word PC intentionally consumes the low six bits
                    // of the signed two's-complement relative offset.
                    pc <= pc + branch_offset[5:0];
                else
                    pc <= pc + 1'b1;
            end
        end
    end

    assign dbg_pc = pc;
    assign dbg_halt = halt_state;
    assign dbg_write_data = reg_write_data;
endmodule
