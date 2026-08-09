`include "config.vh"
`timescale 1ns / 1ps

module test_harness;
    localparam [`ADDR_MSB:0] PID_LOOP_PC = 16'h000E;
    localparam integer PID_ITERATIONS = 1000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [`ADDR_MSB:0] dbg_pc;
    wire dbg_halt;
    reg [255*8-1:0] program_file;
    integer max_cycles;
    integer program_words;
    integer cycle_count;
    integer loops;
    integer start_cycle;
    reg performance_done;

    // 50 MHz simulation clock.
    always #10 clk = ~clk;

    cpu u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .dbg_pc(dbg_pc),
        .dbg_halt(dbg_halt)
    );

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file)) begin
            $display("ERROR: no +PROGRAM=<file> specified");
            $finish;
        end
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles))
            max_cycles = 100000;
        if (!$value$plusargs("PROGRAM_WORDS=%d", program_words))
            program_words = `IMEM_DEPTH;

        // Loading only the generated program range avoids the harmless but
        // noisy "not enough words" warning for short test programs.
        $readmemh(program_file, u_cpu.u_imem.mem, 0, program_words - 1);
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, test_harness);
        // Release reset away from an active clock edge to avoid a race with
        // synchronous CPU and register-file reset logic.
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        cycle_count = 0;
        loops = 0;
        start_cycle = 0;
        performance_done = 1'b0;

        while (!dbg_halt && !performance_done && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            // Sample after the falling edge so all state changed by the prior
            // rising edge is stable. The first visit starts timing; each later
            // visit means one complete PID update has finished.
            @(negedge clk);
            if (dbg_pc == PID_LOOP_PC) begin
                if (loops == 0) begin
                    start_cycle = cycle_count;
                end else if (loops == PID_ITERATIONS) begin
                    $display("PID iterations: %0d", PID_ITERATIONS);
                    $display("Total PID cycles: %0d",
                             cycle_count - start_cycle);
                    $display("Cycles per PID update: %0d",
                             (cycle_count - start_cycle) / PID_ITERATIONS);
                    performance_done = 1'b1;
                end
                loops = loops + 1;
            end
`ifdef TRACE
            $display("[%6d] PC=0x%04h INSTR=0x%08h", cycle_count, dbg_pc, u_cpu.instr);
`endif
        end

        if (dbg_halt)
            $display("CPU halted after %0d cycles", cycle_count);
        else if (performance_done)
            $display("PID performance measurement complete");
        else
            $display("TIMEOUT after %0d cycles (no HALT reached)", cycle_count);

        begin : dump_regs
            integer i;
            for (i = 0; i < `REG_COUNT; i = i + 1)
                $display("r%0d = 0x%08h", i, u_cpu.u_regfile.regs[i]);
        end
        $finish;
    end
endmodule
