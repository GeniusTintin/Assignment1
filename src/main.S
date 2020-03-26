.syntax unified
.global main

.type main, %function
main:
  //First create a triangle signal with approximate 440Hz
  nop
  initialize:
  //free: r12
  //used: r11, r10, r9
  ldr r12, =0x17fff
  ldr r11, =0x20000000
  str r12, [r11,8] //Store 0x17fff
  ldr r12, =0x8000
  str r12, [r11,12] //Store 0x8000
  ldr r10, [r11,8]
  ldr r9, =2
  b down


predown:
  ldr r12, [r11, 8]
  mul r8, r12, r9
  sub r10, r8, r10

down:
  ldr r12, [r11,12]
  cmp r10, r12
  blt preup

  mov r0, r10
  bl BSP_AUDIO_OUT_Play_Sample
  sub r10, 1201
  b down

preup:
  ldr r12, [r11, 12]
  mul r8, r12, r9 
  sub r10, r8, r10 

up:
  ldr r12, [r11, 8]
  cmp r10, r12
  bgt predown
  mov r0, r10
  bl BSP_AUDIO_OUT_Play_Sample
  add r10, 1201
  b up

.size main, .-main