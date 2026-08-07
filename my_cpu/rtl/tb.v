`include "config.vh"
`timescale 1ns / 1ps

module test_harness;

// Clock and reset are driven by the harness so the CPU can execute one
// instruction per cycle during simulation.
reg clk = 0;
reg rst_n = 0;
wire [`ADDR_MSB:0] dbg_pc;
wire dbg_halt;

// 100 MHz clock: one toggle every 10 ns.
always #5 clk = ~clk;

// The CPU instance must expose the debug halt signal so the harness can stop
// the simulation when the program reaches HALT.
cpu u_cpu (
    .clk(clk),
    .rst_n(rst_n),
    .dbg_pc(dbg_pc),
    .dbg_halt(dbg_halt)
);

// Plusargs are supplied by simulate.py and carry the program file path and
// the maximum cycle budget to the testbench at runtime.
reg [255*8-1:0] program_file;
integer max_cycles;
integer cycle_count;

initial begin
    // Load the program file and cycle limit from runtime plusargs.
    if (!$value$plusargs("PROGRAM=%s", program_file)) begin
        $display("ERROR: no +PROGRAM=<file> specified");
        $finish;
    end
    if (!$value$plusargs("MAX_CYCLES=%d", max_cycles))
        max_cycles = 100000;

    // The tutorial requires the instruction memory instance to be named u_imem
    // and its storage array to be named mem. This hierarchical reference loads
    // the hex image into that array.
    $readmemh(program_file, u_cpu.u_imem.mem);

    // Write a VCD trace for waveform inspection if needed.
    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, test_harness);

    // Hold reset low for a few cycles before allowing the CPU to run.
    #25 rst_n = 1;

    // Run until the CPU halts or the cycle limit is reached.
    cycle_count = 0;
    while (!dbg_halt && cycle_count < max_cycles) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
    end

    if (dbg_halt)
        $display("CPU halted after %0d cycles", cycle_count);
    else
        $display("TIMEOUT after %0d cycles (no HALT reached)", cycle_count);

    // The tutorial requires the register file instance to be named u_regfile
    // and its storage array to be named regs. The simulator parses this exact
    // format to verify program results.
    begin : dump_regs
        integer i;
        for (i = 0; i < `REG_COUNT; i = i + 1)
            $display("r%0d = 0x%08h", i, u_cpu.u_regfile.regs[i]);
    end

    $finish;
end

endmodule
