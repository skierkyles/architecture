/*
Architecture assignment

Demonstrates while loop in ARM assembly.

Compile this code. The project options have the simulator selected and
the optimization level low. Download and debug--which will run it in the
simulator. You will not need a launchpad for this.

Use the disassembly window in the IAR Embedded Workbench to find the specific
assembly instructions used to implement the while loop below.

Note that while debugging, you may single-step through the C source code or the
assembly code in the disassembly window. Both windows will highlight the
currently executing line of code. For some lines of C instructions there will
be many assembly instructions.

Submit the assembly instructions implementing the while loop to complete
this assignment.
*/

int main() {
    int counter = 0;

    while (counter < 10) {
        ++counter;
    }

    return 0;
}