`timescale 1ns/1ps
`include "config.vh"

module tb;
    reg clk = 0;
    reg rst = 1;
    integer cycles = 0;
    integer max_cycles = 1000;
    integer i;
    wire halt;
    wire [`ADDR_WIDTH-1:0] dbg_pc;

    cpu dut (.clk(clk), .rst(rst), .halt(halt), .dbg_pc(dbg_pc));
    always #5 clk = ~clk;

    initial begin
        if ($value$plusargs("MAX_CYCLES=%d", max_cycles)) begin end
        #12 rst = 0;
    end

    always @(posedge clk) begin
        if (!rst) begin
            cycles = cycles + 1;
            if (halt) begin
                $display("HALT after %0d cycles at PC=%0d", cycles, dbg_pc);
                for (i = 0; i < `REG_COUNT; i = i + 1)
                    $display("r%0d = 0x%08x", i, dut.u_regfile.regs[i]);
                $finish;
            end
            if (cycles >= max_cycles) begin
                $display("ERROR: timeout after %0d cycles, PC=%0d", cycles, dbg_pc);
                $finish;
            end
        end
    end
endmodule
