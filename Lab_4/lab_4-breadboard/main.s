; Lab 4 Breadboard
;
; This program implements a 4-bit counter on GPIOA pins 2-5. GPIOA pins 6-7
; function as enable controls.
;
; SW1 and SW1 serve as the user interface as follows:
; - SW1 short press and release increments the counter output to the 4-bit bus.
; - SW1 long press toggles between EN1 and EN2 implemented on PA6 and PA7. 
;   Green LED is EN1. Blue LED is EN2.
; - SW2 any press activates EN1 or EN2 depending on mode selected via SW1 long
;   press.
;
; This program also illustrates some high-level programming constructs as 
; implemented in assembly language. It makes use of switch/case and if/else.
;
; The switches are polled by making use of SysTick with interrupts to check the
; switch values at regular intervals.
;
; State is maintained in memory. EN1 and EN2 state is maintained in the LED.

        NAME    main
      
        PUBLIC  main
        PUBLIC SysTick_Handler
        
; See "lm4f120h5qr.h" in arm/inc/TexasInstruments
SYSCTL_RCGCGPIO_R               EQU     0x400FE608
SYSCTL_GPIOHBCTL_R              EQU     0x400FE06C

; GPIOA addresses
GPIO_PORTA_AHB_DATA_BITS_R      EQU     0x40058000
GPIO_PORTA_AHB_DATA_R           EQU     0x400583FC
GPIO_PORTA_AHB_DIR_R            EQU     0x40058400
GPIO_PORTA_AHB_DEN_R            EQU     0x4005851C
GPIO_PORTA_AHB_IS_R             EQU     0x40058404
GPIO_PORTA_AHB_IM_R             EQU     0x40058410
GPIO_PORTA_AHB_PUR_R            EQU     0x40058510

; GPIOF addresses
GPIO_PORTF_AHB_DATA_BITS_R      EQU     0x4005D000
GPIO_PORTF_AHB_DATA_R           EQU     0x4005D3FC
GPIO_PORTF_AHB_DIR_R            EQU     0x4005D400
GPIO_PORTF_AHB_DEN_R            EQU     0x4005D51C
GPIO_PORTF_AHB_IS_R             EQU     0x4005D404
GPIO_PORTF_AHB_IM_R             EQU     0x4005D410
GPIO_PORTF_AHB_ICR_R            EQU     0x4005D41C
GPIO_PORTF_AHB_PUR_R            EQU     0x4005D510
GPIO_PORTF_AHB_AFSEL_R          EQU     0x4005D420
GPIO_PORTF_AHB_LOCK_R           EQU     0x4005D520
GPIO_PORTF_AHB_CR_R             EQU     0x4005D524
UNLOCK_CODE                     EQU     0x4C4F434B      ; This necessary for SW2

; SysTick
NVIC_EN0_R                      EQU     0xE000E100
NVIC_PRI7_R                     EQU     0xE000E41C
NVIC_ST_CTRL_R                  EQU     0xE000E010
NVIC_ST_RELOAD_R                EQU     0xE000E014
NVIC_ST_CURRENT_R               EQU     0xE000E018
NVIC_SYS_PRI3_R                 EQU     0xE000ED20

; Program constants
; systick_reload represents the time interval of our SysTick interrupt.
systick_reload                  EQU     0x0006FFFF      ; Max value 24 bits
counter_mem                     EQU     0x20000000      ; Data to output. See count_limit
sw1_counter_mem                 EQU     0x20000004      ; Store SW1 short press count here
sw2_counter_mem                 EQU     0x20000008      ; store SW2 count here
sw1_long_press_buffer           EQU     0x2000000C      ; Store SW1 long press count here
long_press_count                EQU     0x2F            ; Number of counts to register as long press
count_limit                     EQU     0x16            ; Range to output 0-n. Change this for different count range.

        SECTION .text : CODE (2)
        THUMB

; ---------->% main >%----------
; Initialize and loop.
main
        BL      GPIOA_Init
        BL      GPIOF_Init
        BL      LED_Rotate      ; Set initial state
        
        ; Initialize bus value counter--this is temporary
        LDR     R0, =counter_mem
        MOV     R2, #0          ; Starting value
        STR     R2, [R0]
        
        ; Initialize SW1 counter
        LDR     R0, =sw1_counter_mem
        MOV     R2, #0
        STR     R2, [R0]
        
        ; Initialize SysTick for first count.
        BL      SysTick_Init
        
        ; Loop forever
        B       .
        
; ---------->% SysTick_Handler >%----------
; SysTick fires interrupt periodically. Use it to poll SW1 and SW2.
; Input: None
; Output: None
; Modifies: R0, R1, R3, R4, R5, R6
SysTick_Handler
        PUSH    {LR}

; Switch/Case for SW1 button press
case_sw1_time_delay
        BL      GetSW1Count
        ; If R1 == 0
        CMP     R1, #0
        BNE     case_sw1_short_press_release
        ; Else
        LDR     R5, =sw1_long_press_buffer
        LDR     R6, [R5]
        ; If R6 == 0
        CMP     R6, #0          ; time delay full countdown?
        BEQ     case_sw1_short_press_release
        ; Else
        ; Delay countdown timer
        SBC     R6, R6, #1
        STR     R6, [R5]
        B       case_sw1_done       
case_sw1_short_press_release
        BL      CheckSW1Value
        ; If R1 == 0
        CMP     R1, #0
        BEQ     case_sw1_long_press_hole    ; switch 1 pressed
        ; Else
        BL      GetSW1Count
        ; If R1 == 0
        CMP     R1, #0                  ; zero?
        BEQ     case_sw1_done
        ; Else
        ; If R1 < 10
        CMP     R1, #10                 ; less than 10 systicks increments counter
        BLT     button_press_release    ; This might be kinda hokey. But it works.
        B       case_sw1_done
button_press_release
        BL      Handle_Short_Press_Release
        B       case_sw1_done
        ; Else
        BL      ResetSW1Count
        B       case_sw1_done   
case_sw1_long_press_hole
        BL      IncrementSW1Counter
        BL      GetSW1Count
        CMP     R1, #long_press_count   ; some large number for long press
        BLT     case_sw1_done
        
        ; It is a long press. Handle it here.
        BL      ResetSW1Count
        BL      LED_Rotate
        LDR     R5, =sw1_long_press_buffer
        MOV     R6, #0x20               ; countdown timer
        STR     R6, [R5]
        B       case_sw1_done      
case_sw1_default
        BL      ResetSW1Count      
case_sw1_done
case_sw2_press                          ; Switch/case for SW2 button press
        BL      CheckSW2Value
        ; If R1 == 0
        CMP     R1, #0
        BNE     case_sw2_release        ; switch 2 not pressed
        ; Else
        BL      IncrementSW2Counter
        BL      GetSW2Count
        ; If R1 == 1
        CMP     R1, #1                  ; Is this first counter increment?
        BNE     case_sw2_done           ; Toggle only on first press notice.
        ; Else
        BL      Latch_Toggle
        B       case_sw2_done
case_sw2_release
        BL      GetSW2Count
        ; If R1 == 0
        CMP     R1, #0
        BEQ     case_sw2_default        ; Counter not set. we're done.
        ; Else
        BL      Latch_Toggle
        BL      ResetSW2Count
        B       case_sw2_done
case_sw2_default
        NOP
case_sw2_done
        BL      SysTick_Init            ; Start new SysTick
        POP     {LR}
        BX      LR

; ---------->% Handle_Short_Press_Release >%----------
; Increment data counter and write to PA2345. Reset to zero if at limit.
; Input: None
; Output: None
; Modifies: R0, R1, R3, R4
Handle_Short_Press_Release
        PUSH    {LR}
        BL      ResetSW1Count
        
        ; Load, increment counter.
        LDR     R3, =counter_mem        ; Counter stored here
        LDR     R4, [R3]                ; Count in R4
        ADD     R4, R4, #1              ; Increment by 1
        
        ; Re-init counter if max number
        ; If R4 == count_limit
        CMP     R4, #count_limit
        BNE     store_counter
        ; Else set counter == 0
        MOV     R4, #0
store_counter
        STR     R4, [R3]

        ; Write counnter to PA2345
        LDR     R0, =GPIO_PORTA_AHB_DATA_BITS_R
        ADD     R0, R0, #1111B << 4     ; Address offset for PA2345
        
        ; Shift and output counter bits
        MOV     R1, R4
        LSL     R1, R1, #2
        STR     R1, [R0] 
        POP     {LR}
        BX      LR

; The following several functions could be combined to make 2 functions. But it 
; would add even more code for the caller so I will accept this.

; ---------->% GetSW1Count >%----------
; Input: None
; Output: R1
; Modifies: R0, R1
GetSW1Count
        LDR     R0, =sw1_counter_mem
        LDR     R1, [R0]
        BX      LR
        
; ---------->% GetSW2Count >%----------
; Input: None
; Output: R1
; Modifies: R0, R1
GetSW2Count
        LDR     R0, =sw2_counter_mem
        LDR     R1, [R0]
        BX      LR
        
; ---------->% ResetSW1Count >%----------
; Reset hold count for SW1.
; Input: None
; Output: None
; Modifies: R0, R1
ResetSW1Count
        LDR     R0, =sw1_counter_mem
        MOV     R1, #0
        STR     R1, [R0]
        BX      LR
        
; ---------->% ResetSW2Count >%----------
; Reset hold count for SW2.
; Input: None
; Output: None
; Modifies: R0, R1
ResetSW2Count
        LDR     R0, =sw2_counter_mem
        MOV     R1, #0
        STR     R1, [R0]
        BX      LR
        
; ---------->% CheckSW1Value >%----------
; Check to see if SW1 pressed: Val = 0.
; Input: None
; Output: R1
; Modifies: R0, R1
CheckSW1Value
        MOV     R1, #0
        LDR     R0, =GPIO_PORTF_AHB_DATA_BITS_R
        ADD     R0, R0, #0x40   ; SW1 data bit address offset
        LDR     R1, [R0]        ; Load value into R1. See watch window.
        BX      LR

; ---------->% CheckSW2Value >%----------
; Check to see if SW2 pressed: Val = 0.
; Input: None
; Output: R1
; Modifies: R0, R1
CheckSW2Value
        MOV     R1, #0
        LDR     R0, =GPIO_PORTF_AHB_DATA_BITS_R
        ADD     R0, R0, #1B << 2        ; SW2 data bit address offset
        LDR     R1, [R0]        ; Load value into R1. See watch window.
        BX      LR
        
; ---------->% IncrementSW1Counter >%----------
; Increment the SW1 counter saved in memory at location sw1_counter_mem.
; Input: None
; Output: None
; Modifies R0, R1
IncrementSW1Counter
        ; Increment SW1 press counter
        LDR     R0, =sw1_counter_mem
        LDR     R1, [R0]
        ADD     R1, R1, #1      ; Increment by 1
        STR     R1, [R0]        ; Put it back
        BX      LR

; ---------->% IncrementSW2Counter >%----------
; Increment the SW2 counter saved in memory at location sw1_counter_mem.
; Input: None
; Output: None
; Modifies R0, R1
IncrementSW2Counter
        ; Increment SW2 press counter
        LDR     R0, =sw2_counter_mem
        LDR     R1, [R0]
        ADD     R1, R1, #1      ; Increment by 1
        STR     R1, [R0]        ; Put it back
        BX      LR
        
; ---------->% Latch_Toggle >%----------
; LED Color stores mode state. Test each color bit to determine which PA6,7 is
; active. Toggle active bit 0=>1 or 1=>0.
; Input: None
; Output: None
; Modifies: R0, R1, R2, R3
Latch_Toggle
        ; Fetch LED color bits for green and blue PF2,3
        LDR     R0, =GPIO_PORTF_AHB_DATA_BITS_R
        ADD     R0, R0, #11B << 4       ; GPIOF LED Bits offset PF12
        LDR     R1, [R0]

; Switch/Case
case_mode_green        
        ANDS    R2, R1, #1B << 3        ; Test green
        CBZ     R2, case_mode_blue      ; Not green.
        B       case_mode_done          ; Use R2 for PA6,7      
case_mode_blue
        ANDS    R2, R1, #1B << 2        ; Test blue     
        CBZ     R2, case_mode_default   ; Not blue
        B       case_mode_done          ; Use R2 for PA6,7        
case_mode_default
        BX      LR                      ; Don't do anything       
case_mode_done
        LDR     R0, =GPIO_PORTA_AHB_DATA_BITS_R
        ADD     R0, R0, #11B << 8       ; For PA6,7 only
        LSL     R2, R2, #4              ; PF23 -> PA67
        LDR     R1, [R0]                ; Current PA67
        ANDS    R3, R2, R1
        CBZ     R3, latch_set           ; Zero means bit not set. Set it.
        BIC     R2, R2, R2              ; Non-zero means bit set. Clear it.
latch_set
        STR     R2, [R0]
        BX      LR
        
; ---------->% LED_Rotate >%----------
; Rotate LED colors throught Green=>Blue=>Red. Color also serves as state for
; SW2 action. This code copied and pasted from Lab 3.
; Input: None
; Output: None
; Modifies: R0, R1
LED_Rotate
        ; Read, modify, write LED color bits
        LDR     R0, =GPIO_PORTF_AHB_DATA_BITS_R
        ADD     R0, R0, #11B << 4      ; GPIOF LED Bits offset PF12
        LDR     R1, [R0]        ; Fetch current LED color
        LSR     R1, R1, #1      ; Right shift LED color bit
        BIC     R1, R1, #3      ; Clear SW2 bit
        CBNZ    R1, SetLED      ; Branch to SetLED if result non-zero.
        MOV     R1, #0x08       ; Hit zero, re-init LED color to green.
SetLED
        STR     R1, [R0]        ; New LED colors
        BX      LR
        
; ---------->% Set_GPIOA_Direction_In >%---------
; R2 holds the bit map corresponding to the pins we set direction on. Perform
; bit clear on current contents of GPIO_PORTA_AHB_DIR_R. 0 = In.
; Input: R2
; Output: None
; Modifies: None
Set_GPIOA_Direction_In
        LDR     R0, =GPIO_PORTA_AHB_DIR_R
        LDR     R1, [R0]
        BIC     R1, R1, R2
        STR     R1, [R0]
        BX      LR
        
; ---------->% Set_GPIOA_Direction_Out >%----------
; R2 holds the bit map corresponding to the pins we set direction on. Perform
; bitwise AND on current contents of GPIO_PORTA_AHB_DIR_R. 1 = Out.
; Input: R2
; Output: None
; Modifies: None
Set_GPIOA_Direction_Out
        LDR     R0, =GPIO_PORTA_AHB_DIR_R
        LDR     R1, [R0]
        ORR     R1, R1, R2
        STR     R1, [R0]
        BX      LR
        
; ---------->% SysTick_Init >%----------
; Initialize SysTick timer with interrupts. SysTick timer will count down
; systick_reload + 1 until it reaches zero. Then it will fire the interrupt.
; Interrupt will be handled by SysTick_Handler.
; Input: None
; Output: None
; Modifies: R0, R1
SysTick_Init
        ; Disable SysTick during init
        PUSH    {LR}                    ; Save LR for later.
        BL      SysTick_Disable         ; Must disable while initializing.
        
        ; Reload value...clock ticks in SysTick counter
        LDR     R0, =NVIC_ST_RELOAD_R   ; See datasheet p140
        LDR     R1, =systick_reload     ; Wait systick_reload + 1 clock cycles
        STR     R1, [R0]
        
        ; Clear Current value
        LDR     R0, =NVIC_ST_CURRENT_R  ; See datasheet p141
        MOV     R1, #0                  ; SysTick Current Value Register
        STR     R1, [R0]
        
        ; Set interrupt priority
        LDR     R0, =NVIC_SYS_PRI3_R    ; NVIC interrupt 15 priority register
        MOV     R1, #0x40000000         ; SysTick bits
        STR     R1, [R0]
        
        BL      SysTick_Enable          ; SysTick on
        POP     {LR}                    ; Grab return PC from stack.
        BX      LR

; ---------->% SysTick_Enable >%----------
; Enable SysTick
; Input: None
; Output: None
; Modifies: R0, R1
SysTick_Enable
        LDR     R0, =NVIC_ST_CTRL_R     ; See datasheet p138
        MOV     R1, #7                  ; SysTick Control and Status Register
        STR     R1, [R0]
        BX      LR
        
; ---------->% SysTick_Disable >%----------
; Disable SysTick
; Input: None
; Output: None
; Modifies: R0, R1
SysTick_Disable
        LDR     R0, =NVIC_ST_CTRL_R     ; See datasheet p138
        MOV     R1, #0                  ; SysTick Control and Status Register
        STR     R1, [R0]
        BX      LR

; ---------->% GPIOA_Init >%----------
; Enable PA2-7 as digital outputs.
; Input: None
; Output: None
; Modifies: R0, R1
GPIOA_Init
        PUSH    {LR}
        ; Enable GPIOA AHB
        LDR     R0, =SYSCTL_GPIOHBCTL_R
        MOVS    R1, #0x01       ; GPIOA
        STR     R1, [R0]
        
        ; Enable GPIOA clock
        LDR     R0, =SYSCTL_RCGCGPIO_R
        MOVS    R1, #0x01       ;clockA
        STR     R1, [R0]
        
        ; GPIOA digital enable PA2-7
        LDR     R0, =GPIO_PORTA_AHB_DEN_R
        MOV     R1, #111111B << 2
        STR     R1, [R0]
        
        ; GPIOA direction out PA2-7
        MOV     R2, #111111B << 2
        BL      Set_GPIOA_Direction_Out
        POP     {LR}
        BX      LR
        
; ---------->% GPIOF_Init >%----------
; Initialize GPIO Port F.
; Input: None
; Output: None
; Modifies: R0, R1
GPIOF_Init
        PUSH    {LR}
        ; Enable GPIOF Advanced High Performance Bus
        LDR     R0, =SYSCTL_GPIOHBCTL_R ; See datasheet p258
        LDR     R1, [R0]                ; SYSCTL_GPIOHBCTL_R value to R1
        ORR     R1, R1, #1B << 5        ; GPIOF AHB enable bit set
        STR     R1, [R0]
        
        ; Enable GPIOF clock
        LDR     R0, =SYSCTL_RCGCGPIO_R  ; See datasheet p340
        LDR     R1, [R0]                ; SYSCTL_RCGCGPIO_R value to R1
        ORR     R1, R1, #1B << 5        ; GPIOF clock enable
        STR     R1, [R0]

        ; SW2 is an Alternate Function Select bit. Need to unlock it and set
        ; the commit bit before the AFSEL can be set and SW2 configured for 
        ; use.
        ; Unlock
        LDR     R0, =GPIO_PORTF_AHB_LOCK_R
        LDR     R1, =UNLOCK_CODE
        STR     R1, [R0]
        
        ; Clear for commit
        LDR     R0, =GPIO_PORTF_AHB_CR_R
        MOV     R1, #1B
        STR     R1, [R0]
        
        ; Enable SW2 Alternate Function Select so we can use it as a switch.
        LDR     R0, =GPIO_PORTF_AHB_AFSEL_R     ; See p671
        LDR     R1, [R0]
        ORR     R1, R1, #1              ; SW2 is bit 0
        STR     R1, [R0]
        
        ; GPIOF direction
        LDR     R0, =GPIO_PORTF_AHB_DIR_R       ; See datasheet p663
        LDR     R1, [R0]                ; GPIO_PORTF_AHB_DIR_R value to R1
        ORR     R1, R1, #0x0E           ; GPIOF PF4 direction PF123 output
        STR     R1, [R0]                ; PF0,4 (SW1, SW2) is input by default.
        
        ; GPIOF digital enable
        LDR     R0, =GPIO_PORTF_AHB_DEN_R       ; See datasheet p682
        LDR     R1, [R0]                ; GPIO_PORTF_AHB_DEN_R value to R1
        ORR     R1, R1, #0x1F           ; Set PF01234 as digital
        STR     R1, [R0]
        
        ; GPIOF PF0,4 pull up resistor for logic HIGH until SW1,SW2 press.
        LDR     R0, =GPIO_PORTF_AHB_PUR_R       ; p677 GPIO Pull-Up Select
        LDR     R1, [R0]
        ORR     R1, R1, #1B << 4                ; SW1 pull up resistor
        ORR     R1, R1, #1B                     ; SW2 pull up resistor
        STR     R1, [R0]

        POP     {LR}
        BX      LR

        END
