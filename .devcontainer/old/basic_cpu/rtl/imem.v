`include "config.vh"

module imem (
    input  wire [`ADDR_WIDTH-1:0] address,
    output wire [`INSTR_WIDTH-1:0] instruction
);
    reg [`INSTR_WIDTH-1:0] memory [0:`IMEM_DEPTH-1];
    reg [1023:0] init_file;

    initial begin
        init_file = "";
        if (!$value$plusargs("PROGRAM=%s", init_file))
            init_file = "build/test_add.hex";
        $readmemh(init_file, memory);
    end

    assign instruction = (address < `IMEM_DEPTH) ? memory[address] : 0;
endmodule
