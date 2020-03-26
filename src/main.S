.syntax unified
.global main

.type main, %function
main:
  //First create a triangle signal with approximate 440Hz
  nop
  initialize:
  ldr r12, =0x17fff
  ldr r11, =0x8000
  mov r10, r12
  ldr r9, =2
  b down

predown:
  mul r8, r12, r9
  sub r10, r8, r10

down:

  mov r0, r10
  bl BSP_AUDIO_OUT_Play_Sample

  sub r10, 1201
  cmp r10, r11
  blt preup

  b down

preup:
  mul r8, r11, r9 
  sub r10, r8, r10 

up:
  mov r0, r10
  bl BSP_AUDIO_OUT_Play_Sample

  add r10, 1201
  cmp r10, r12
  bgt predown

  b up

.size main, .-main