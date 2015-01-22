// processor definitions
#include "tm4c123g.h"
#define LED_RED 0x2
#define LED_BLUE 0x4
#define LED_GREEN 0x8

void main(void) {
  // enable PORT F GPIO peripheral
  SYSCTL_RCGC2_R = SYSCTL_RCGC2_GPIOF;
  // set LED PORT F pins as outputs
  GPIO_PORTF_DIR_R = LED_RED|LED_BLUE|LED_GREEN;
  // enable digital for LED PORT F pins
  GPIO_PORTF_DEN_R = LED_RED|LED_BLUE|LED_GREEN;
  // clear all PORT F pins
  GPIO_PORTF_DATA_R = 0;
  // set LED PORT F pins high
  GPIO_PORTF_DATA_R |= LED_RED|LED_BLUE|LED_GREEN;
  // loop forever
  for(;;);
}