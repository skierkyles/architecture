/*
Architecture assignment

Demonstrates function call and the AAPCS calling convention. See section 6.4.6
Function Calls in Digital Design and Computer Architecture.

Compile this code. The project options have the simulator selected and
the optimization level low. Download and debug--which will run it in the
simulator. You will not need a launchpad for this.

Use the disassembly window in the IAR Embedded Workbench to find the specific
assembly instructions used to implement the if statement below.

Note that while debugging, you may single-step through the C source code or the
assembly code in the disassembly window. Both windows will highlight the
currently executing line of code. For some lines of C instructions there will
be many assembly instructions.

1. How do the function arguments to sum get passed?
2. Which registers are used for function arguments?
3. Which registers are pushed onto the stack?
4. What is the address of the top of the stack before and after sum() is called?
5. Why is the stack used for the additional function arguments?
6. Which register is used for the return value?
*/

int main() {
    int counter = 0;
    int a = 1;
    int b = 2;
    int c = 3;
    int d = 4;
    int e = 5;
    int f = 6;

    while (counter < 5) {
        ++counter;
        int added = sum(counter, a, b, c, d, e, f);
    }

    return 0;
}

int sum(int counter, int a, int b, int c, int d, int e, int f) {
    int sum = counter + a + b + c + d + e + f;
    return sum;
}