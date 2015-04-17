/*
Architecture assignment

Demonstrates an array in ARM assembly.

Compile this code. The project options have the simulator selected and
the optimization level low. Download and debug--which will run it in the 
simulator. You will not need a launchpad for this.

Use the disassembly window in the IAR Embedded Workbench to find the specific
assembly instructions used to implement the array below.

Note that while debugging, you may single-step through the C source code or the
assembly code in the disassembly window. Both windows will highlight the 
currently executing line of code. For some lines of C instructions there will
be many assembly instructions.

Submit the assembly instructions implementing the array to complete
this assignment. You should include the for loop as well since the loop
variable is used to access the array elements.

Note the subtle difference from Code Example 6.21 in Digital Design and 
Computer Architecture. The IAR Embedded Workbench chooses to use SP to store
and index into the array.
*/

int main() {
    int volatile array[5];

    for (int i=0; i<5; i++) {
        array[i] = i;
    }

    return 0;
}