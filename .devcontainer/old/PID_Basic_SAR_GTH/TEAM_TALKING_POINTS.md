# PID CPU constraints — team talking points

## Main point

- Both CPUs can calculate the P, I, and D terms.
- Both CPUs use 32-bit two's-complement arithmetic, so `ADD`, `SUB`, and the
  tested `MUL` operations can handle positive and negative values.
- The main differences appear when we scale the result and send it to real
  hardware.

## PID_Basic

- PID_Basic has no arithmetic shift, comparison, or conditional branch.
- A general signed divide-by-256 routine would need logic like:

```c
negative = output < 0;

if (negative)
    output = -output;

while (output >= 256) {
    output -= 256;
    scaled_output++;
}

if (negative)
    scaled_output = -scaled_output;
```

- PID_Basic cannot implement this general routine with its current ISA.
- The test avoids that problem by choosing a positive final output.
- Its negative integral gain is fixed in the program as `0 - 64`.
- `MUL` then correctly produces the negative I term.
- The final result is still positive: `P + I + D = 8 - 5 + 1 = 4`.
- Scaling is hardcoded by writing four `SUB`/`ADD` pairs into the assembly.
- The other fractional test writes nine pairs because its known answer is 9.
- If the sensor input or PID result changes, those hardcoded answers do not
  change.
- Therefore, this proves selected arithmetic examples, not a general runtime
  PID scaling solution.

## PID_Basic_SAR

- PID_Basic_SAR adds arithmetic right shift.
- It can scale a calculated fixed-point result with one instruction:

```asm
SAR r12, r11, #8
```

- The same instruction works for positive and negative results.
- It uses the value calculated at runtime rather than a hardcoded answer.
- This makes its fixed-point scaling much more realistic than PID_Basic.
- SAR only handles power-of-two scaling; it does not provide output clamping.

## Constraint shared by both CPUs

- Neither CPU currently clamps the final output.
- A motor PWM may only accept a range such as `0` to `255`.
- A safe controller would need logic like:

```c
if (output < 0)
    output = 0;

if (output > 255)
    output = 255;
```

- CMP and conditional branching can implement these checks.
- A dedicated saturation or clamp instruction could also implement them.
- Without clamping, an out-of-range value may be truncated, wrap around, or be
  interpreted incorrectly by the peripheral.
- The CPU could only control a motor safely if software guarantees the range or
  an external peripheral performs the clamping.
- Adding CPU-side clamping gives the design a realistic motor-control use case.

## Number-size constraint

- Both CPUs keep only a bounded 32-bit result.
- Very large gains, errors, or integral values can overflow and wrap around.
- Clamping the actuator output does not prevent an earlier multiplication or
  integral overflow.
- A practical PID also needs bounded gains, bounded state, and usually integral
  anti-windup.

## Short presentation script

- “The Basic CPU can perform the PID arithmetic, including negative
  intermediates, because it uses two's-complement arithmetic.”
- “Its fractional tests are limited because the divide-by-256 result is
  hardcoded as repeated subtraction.”
- “The SAR CPU scales the actual positive or negative runtime result in one
  instruction, so its fixed-point behavior is more realistic.”
- “Neither current CPU clamps the result to an actuator range such as PWM 0 to
  255.”
- “For safe motor control, we need comparison and conditional branching, a
  clamp instruction, or an external peripheral that performs the limiting.”
- “We also need bounds or anti-windup so the 32-bit PID calculations do not
  overflow before the final clamp.”
