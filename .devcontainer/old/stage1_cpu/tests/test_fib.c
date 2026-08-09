// Stage 3 stress test.
//
// Exercises:
//   - double recursion (fib)
//   - single recursion (triangular)
//   - nested calls and values live across calls
//   - three register arguments
//   - <, > and == control flow
//   - ADD/SUB with positive and negative constants
//   - stack frames, LR save/restore, spills and reloads
//
// It intentionally avoids multiply, divide, bitwise operators and arrays;
// those require ISA/backend features beyond the current Stage 3 CPU.

__attribute__((noinline))
int fib(int n) {
    if (n < 2)
        return n;

    return fib(n - 1) + fib(n - 2);
}

__attribute__((noinline))
int triangular(int n) {
    if (n < 1)
        return 0;

    return n + triangular(n - 1);
}

__attribute__((noinline))
int branch_mix(int first, int second, int limit) {
    int difference;

    if (first > second)
        difference = first - second;
    else
        difference = second - first;

    if (difference < limit)
        difference = difference + limit;
    else
        difference = difference - limit;

    if (difference == 0)
        return limit + 1;

    return difference;
}

__attribute__((noinline))
int nested_score(int depth) {
    if (depth < 1)
        return 3;

    int fib_value = fib(depth + 2);
    int triangle_value = triangular(depth + 3);
    int mixed = branch_mix(fib_value, triangle_value, depth);

    return mixed + nested_score(depth - 1);
}

int main(void) {
    int nested = nested_score(4);       // 49
    int fib_value = fib(8);             // 21
    int triangle_value = triangular(9); // 45
    int mixed = branch_mix(nested, fib_value, triangle_value); // 73

    // Expected final value in the return register r8:
    // 49 + 21 + 45 + 73 = 188 (0x000000bc).
    return nested + fib_value + triangle_value + mixed;
}
