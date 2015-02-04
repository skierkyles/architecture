  PUBLIC __iar_program_start

  SECTION .intvec:CODE (2)
  DATA
  DC32 __iar_program_start // The Stack Pointer
  DC32 0x01000000U // Really 0x4

  SECTION LAB1:CODE (2)
  THUMB
  
__iar_program_start
  B main
main NOP
  B main
  END