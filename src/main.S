.syntax unified
.global main

.type main, %function
main:
//First determain the length of each value:
//0x17FFF->0x8000->0x17FFF  :This is the range we could use to bounce between the dynamic range
//(16^4*2*440)/48000=1201.49  : This is the optimal length of each step in the signal
//To derive 1201.5 we could stagger between 1201 and 1202
//i.e. odd: subtract/add 1201, even: subtract/add 1202 

//Following is How things work!
//used registers: r6, r12, 
//free registers: r11, r9, r7
  nop
  bl init
  ldr r6, =0x200000b4
  ldr r12, =0x1 //determine odd and even approach
  ldr r11, =0x17fff //0x200000b0+32
  str r11, [r6, 32] //store in memory to protect the value
  ldr r9, =0x8000 //0x200000b0+36
  str r9, [r6, 36]
  ldr r8, =1201
  str r8, [r6, 48] //parameter of step
  ldr r8, =48000
  str r8, [r6, 52] // sampling rate
  ldr r7, =0x2  // a parameter used in mul function
  str r7, [r6, 40]
  ldr r7, =0x1  // a parameter used for counting (1:200)
  str r7, [r6, 44]
  
  //actually create a queue for the moving average filter
  str r11, [r6, 0]
  str r11, [r6, 4]
  str r11, [r6, 8]
  str r11, [r6, 12]
  str r11, [r6, 16]
  str r11, [r6, 20]
  str r11, [r6, 24]
  mov r10, r11
  b downassign

  //This is when signal turning from over 0x17fff to downward
predown:
  ldr r11, [r6, 32]
  ldr r7, [r6, 40]
  bl switch
  //derive 2*0x17fff
  //2*0x17fff-Current value(is the value that mapped back) 
  b downassign

down:
  cmp r12, 1
  beq dodd
  cmp r12, 0
  beq deven

dodd:
  //ldr r8, [r6, 48]
  bl FrequencyChanger
  sub r10, r8
  b dsub
deven:
  //ldr r8, [r6, 48]
  bl FrequencyChanger
  sub r10, r8
  sub r10, 1

dsub:
  ldr r9, [r6, 36]
  cmp r10, r9 //if less than 0x8000, turn upward
  blt preup

downassign:
  mov r0, r10

  bl addAssign
 
  lsr r0, 3 
  //and r0, r8
  bl BSP_AUDIO_OUT_Play_Sample

  //Shift the queue
  bl shiftQueue

  eor r12, 1 //parity inversion
  ldr r7, [r6, 44]
  add r7, 1
  str r7, [r6, 44]

  ldr r8, [r6, 52]
  cmp r7, r8
  IT EQ
  bleq clearCounter

  b down

  //This is when signal turning from less than 0x8000 to upward
preup:
  ldr r11, [r6, 36]
  ldr r7, [r6, 40]
  bl switch
  //derive 2*0x8000
  //2*0x8000-Current value(is the value that mapped back)
  b upassign

up:
  cmp r12, 1
  beq uodd
  cmp r12, 0
  beq ueven

uodd:
  bl FrequencyChanger
  add r10, r8
  
  b usub
ueven:
  bl FrequencyChanger
  add r10, r8
  add r10, 1

usub:
  ldr r11, [r6, 32]
  cmp r10, r11 //if more than 0x17fff, turn downward
  bgt predown

upassign:

  mov r0, r10
  
  bl addAssign

  lsr r0, 3 
  bl BSP_AUDIO_OUT_Play_Sample

  //Shift the queue
  bl shiftQueue

  eor r12, 1  //parity inversion
  ldr r7, [r6, 44]
  add r7, 1
  str r7, [r6, 44]
  
  ldr r8, [r6, 52]
  cmp r7, r8
  IT EQ
  bleq clearCounter

  b up

.size main, .-main

.type switch, %function
switch:
  mul r9, r11, r7
  sub r10, r9, r10
  bx lr
.size switch, .-switch

.type clearCounter, %function
clearCounter:
  mov r7, 1
  str r7, [r6, 44]
.size clearCounter, .-clearCounter

.type FrequencyChanger, %function
FrequencyChanger:
  ldr r8, [r6, 48] //step length

  ldr r11, [r6, 52] // sampling rate
  ldr r9, [r6, 40] //constant 2
  ldr r7, [r6, 44] //counter
  udiv r11, r11, r9

  cmp r7, r11
  blt skip
  //ldr r9, [r6, 40]
  mul r8, r9
  //add r8, r9
  skip:
  bx lr
.size FrequencyChanger, .-FrequencyChanger


.type addAssign, %function
addAssign:
  ldr r5, [r6, 24]
  add r0, r5
  ldr r5, [r6, 20]
  add r0, r5
  ldr r5, [r6, 16]
  add r0, r5
  ldr r5, [r6, 12]
  add r0, r5
  ldr r5, [r6, 8]
  add r0, r5
  ldr r5, [r6, 4]
  add r0, r5
  ldr r5, [r6, 0]
  add r0, r5
  bx lr

.size addAssign, .-addAssign

.type shiftQueue, %function
shiftQueue:
  ldr r5, [r6, 20]
  str r5, [r6, 24]
  ldr r5, [r6, 16]
  str r5, [r6, 20]
  ldr r5, [r6, 12]
  str r5, [r6, 16]
  ldr r5, [r6, 8]
  str r5, [r6, 12]
  ldr r5, [r6, 4]
  str r5, [r6, 8]
  ldr r5, [r6, 0]
  str r5, [r6, 4]
  str r10, [r6, 0]

  bx lr
.size shiftQueue, .-shiftQueue