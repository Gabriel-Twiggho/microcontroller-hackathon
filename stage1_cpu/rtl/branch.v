`include "config.vh"

module branch (
    input  wire [`ADDR_MSB:0] pc_current,
    input  wire [`DATA_MSB:0] condition,
    input  wire [`DATA_MSB:0] link_value,
    input  wire [`ADDR_MSB:0] target_field,
    input  wire                 target_absolute,
    input  wire                 jump,
    input  wire                 jump_zero,
    input  wire                 jump_not_zero,
    input  wire                 jump_less,
    input  wire                 jump_greater,
    input  wire                 call,
    input  wire                 ret,
    output wire [`ADDR_MSB:0] pc_next,
    output wire                 branch_taken
);
    wire condition_zero = (condition == {`DATA_WIDTH{1'b0}});
    wire condition_negative = condition[`DATA_MSB];
    wire condition_positive = !condition_negative && !condition_zero;

    wire condition_met = jump
                       || (jump_zero && condition_zero)
                       || (jump_not_zero && !condition_zero)
                       || (jump_less && condition_negative)
                       || (jump_greater && condition_positive)
                       || call
                       || ret;

    // Label offsets emitted by asm.py are relative to the branch instruction
    // itself, so a relative offset of zero targets the current PC.
    wire [`ADDR_MSB:0] relative_target =
        pc_current + $signed(target_field);
    wire [`ADDR_MSB:0] decoded_target =
        target_absolute ? target_field : relative_target;
    wire [`ADDR_MSB:0] selected_target =
        ret ? link_value[`ADDR_MSB:0] : decoded_target;

    assign branch_taken = condition_met;
    assign pc_next = condition_met ? selected_target : (pc_current + 1'b1);
endmodule
