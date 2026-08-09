`include "config.vh"
`timescale 1ns / 1ps

module test_harness;
    localparam [5:0] PID_LOOP_PC = 6'd15;
    localparam integer PID_ITERATIONS = 1000;
    reg clk = 0;
    reg rst_n = 0;
    wire [5:0] dbg_pc;
    wire dbg_halt;
    integer max_cycles;
    integer program_words;
    integer cycle_count;
    integer loops;
    integer start_cycle;
    reg performance_done;
    reg [5:0] last_pc;
    reg [255*8-1:0] program_file;

    always #10 clk = ~clk;
    cpu u_cpu (.clk(clk), .rst_n(rst_n), .dbg_pc(dbg_pc), .dbg_halt(dbg_halt));

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file)) begin
            $display("ERROR: no +PROGRAM=<file> specified");
            $finish;
        end
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 100000;
        if (!$value$plusargs("PROGRAM_WORDS=%d", program_words)) program_words = `IMEM_DEPTH;
        $readmemh(program_file, u_cpu.u_imem.mem, 0, program_words - 1);
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        cycle_count = 0;
        loops = 0;
        start_cycle = 0;
        performance_done = 0;
        last_pc = 6'h3f;

        while (!dbg_halt && !performance_done && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            @(negedge clk);
            if (dbg_pc == PID_LOOP_PC && last_pc != PID_LOOP_PC) begin
                if (loops == 0) start_cycle = cycle_count;
                else if (loops == PID_ITERATIONS) begin
                    $display("PID iterations: %0d", PID_ITERATIONS);
                    $display("Total PID cycles: %0d", cycle_count - start_cycle);
                    $display("Cycles per PID update: %0d", (cycle_count - start_cycle) / PID_ITERATIONS);
                    performance_done = 1;
                end
                loops = loops + 1;
            end
            last_pc = dbg_pc;
        end

        if (performance_done) $display("PID performance measurement complete");
        else if (dbg_halt) $display("CPU halted after %0d cycles", cycle_count);
        else $display("TIMEOUT after %0d cycles", cycle_count);
        begin : dump_regs
            integer i;
            for (i = 0; i < `REG_COUNT; i = i + 1)
                $display("r%0d = 0x%04h", i, u_cpu.u_regfile.regs[i]);
        end
        $display("Actuator output [0x10E] = 0x%04h",
                 u_cpu.u_dmem.mem[9'h10E >> 1]);
        $finish;
    end
endmodule
