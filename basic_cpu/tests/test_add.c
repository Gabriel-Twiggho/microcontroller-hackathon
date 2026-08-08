// Stage 1 compiler test: arguments arrive in r8/r9 and the result returns in r8.
__attribute__((noinline))
int add(int a, int b) {
    return a + b;
}
