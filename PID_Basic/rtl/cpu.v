`include "config.vh"

// Stage 0 top level: fetch wiring and the required debug interfaces are in
// place. Stage 1 adds decode, register read, ALU, write-back, and HALT.
module cpu (
    input  wire                 clk,
    input  wire                 rst_n,
    output wire [`ADDR_MSB:0]   dbg_pc,
    output wire                 dbg_halt
);
    reg [`ADDR_MSB:0] pc;
    wire [`INSTR_WIDTH-1:0] instr;

    imem u_imem (
        .address(pc),
        .instruction(instr)
    );

    // Required Stage 0 instance name. It will be connected to the datapath in
    // Stage 1; unused ports are safely tied off for this non-executing scaffold.
    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .read_addr_a({`REG_ADDR_W{1'b0}}),
        .read_addr_b({`REG_ADDR_W{1'b0}}),
        .read_data_a(),
        .read_data_b(),
        .write_enable(1'b0),
        .write_addr({`REG_ADDR_W{1'b0}}),
        .write_data({`DATA_WIDTH{1'b0}})
    );

    always @(posedge clk) begin
        if (!rst_n)
            pc <= `PC_INIT;
        else
            pc <= pc + 1'b1;
    end

    assign dbg_pc = pc;
    assign dbg_halt = 1'b0;
endmodule
