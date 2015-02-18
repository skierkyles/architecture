; Lab 2 Processor Exceptions
;
; Demonstrate processor exception handling.

        NAME    main

        PUBLIC __iar_program_start

Stack                   EQU     0x20008000      ; SP
GPIO_PORTF_DATA_BITS_R  EQU     0x400253FC      ; GPIOF data all bits

; Vector Table
; Limited to processor exception handlers. Do you recognize the first two
; lines of the vector table?
        SECTION .intvec : CODE (2)
        DATA
        DC32    Stack                   ; 0x00000000   0   - Stack Pointer
        DC32    __iar_program_start     ; 0x00000004   1   - Reset Handler
        DC32    NMI_Handler             ; 0x00000008   2   - NMI Handler
        DC32    HardFault_Handler       ; 0x0000000C   3   - Hard Fault Handler
        DC32    MemManage_Handler       ; 0x00000010   4   - MPU Fault Handler
        DC32    BusFault_Handler        ; 0x00000014   5   - Bus Fault Handler
        DC32    UsageFault_Handler      ; 0x00000018   6   - Usage Fault Handler
        DC32    0                       ; 0x0000001C   7   - Reserved
        DC32    0                       ; 0x00000020   8   - Reserved
        DC32    0                       ; 0x00000024   9   - Reserved
        DC32    0                       ; 0x00000028  10   - Reserved
        DC32    SVC_Handler             ; 0x0000002C  11   - SVCall Handler
        DC32    DebugMon_Handler        ; 0x00000030  12   - Debug Monitor Handler
        DC32    0                       ; 0x00000034  13   - Reserved
        DC32    PendSV_Handler          ; 0x00000038  14   - PendSV Handler
        DC32    SysTick_Handler         ; 0x0000003C  15   - SysTick Handler

        SECTION .text : CODE (2)
        THUMB

; Reset Vector
__iar_program_start
        B       main

; Processor Exception Handlers. Attach them all to this loop.
NMI_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
        B       .               ; Loop here forever.
                                ; Now look at the stack!

HardFault_Handler
        B       .               ; Handle this separately

; The main loop.
main
        BL      CauseMemFault   ; Note the SP register
        B       .               ; Loop forever

; ---------->% CauseMemFault >%----------
; GPIO ports are run mode clock gated. They must be turned on before accessing.
; This attempt to write a value will cause a processor hard fault.
; Input: None
; Output: None
; Modifies: R0, R1
CauseMemFault
        LDR     R0, =GPIO_PORTF_DATA_BITS_R     ; GPIOF data all bits
        MOVS    R1, #0x02       ; LED red
        STR     R1, [R0]        ; BOOM!
        NOP                     ; Pause, wait for it...!
        BX      LR              ; Return to caller

        END
