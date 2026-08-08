`include "config.vh"

module regfile (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wr_en,
    input  wire [`REG_ADDR_W-1:0]  wr_addr,
    input  wire [`DATA_MSB:0]      wr_data,
    input  wire [`REG_ADDR_W-1:0]  rd_addr_a,
    input  wire [`REG_ADDR_W-1:0]  rd_addr_b,
    output wire [`DATA_MSB:0]      rd_data_a,
    output wire [`DATA_MSB:0]      rd_data_b
);
    // The testbench reads this array through u_regfile.regs.
    reg [`DATA_MSB:0] regs [0:`REG_COUNT-1];
    integer i;

    // Two asynchronous read ports. r0 always reads as zero.
    assign rd_data_a = (rd_addr_a == 0) ? {`DATA_WIDTH{1'b0}}
                                         : regs[rd_addr_a];
    assign rd_data_b = (rd_addr_b == 0) ? {`DATA_WIDTH{1'b0}}
                                         : regs[rd_addr_b];

    // One synchronous write port. Writes to r0 are discarded.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < `REG_COUNT; i = i + 1)
                regs[i] <= {`DATA_WIDTH{1'b0}};
        end else if (wr_en && wr_addr != 0) begin
            regs[wr_addr] <= wr_data;
        end
    end
endmodule
