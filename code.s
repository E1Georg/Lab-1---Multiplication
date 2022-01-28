start:

@ set variables:

a_var: .word 0xD
b_var: .word 0xfffffff7

@ multiplication number to register r1:

ADR r4, a_var
ldr r1, [r4]

@ coefficient to register r2:

ADR r4, b_var
ldr r2, [r4]

@ sum of partial multiplications to register r3:

mov r3, #0

@ check for negative sign of a number:
@ if the final multiplication is negative, then r10 will be equal to 1

mov r10, #0
tst r1, #0x80000000
beq leap
add r10, r10, #1

leap:
tst r2, #0x80000000
beq next_leap
add r10, r10, #1 

@ null check:

next_leap:	
cmp r1, #0
bne zero_leap
mov r10, #0

zero_leap: 
cmp r2, #0
bne final_leap
mov r10, #0
final_leap:

@ End of checks. Setting in registers r1 and r2 a 16 - bit value:

mov r4, #65536
sub r4, r4, #1
and r1, r1, r4
and r2, r2, r4

@ installing the mask to r4:
mov r4, #1

@ installation of n + 1 register bit to r6:
mov r6, #0

@ setting to r5 register the reciprocal of the multiplication number. This is a service operation:
mov r9, #65536
sub r5, r9, r1

@ installing the counter of stack operations:
mov r0, #0

@ Multiplier analysis. It is the main stage:

compare:

@ analysis by value from a mask:
@ set flag values to r7. Set values from previous bit to r8:

tst r2, r4 
beq label
mov r7, #1
mov r8, r7
sub r7, r6, r7
b check_flag

label:
mov r7, #0
mov r8, r7
sub r7, r6, r7

@ checking values in a flag:

check_flag:
cmp r7, #1
beq first
cmp r7, #-1
beq second
cmp r7, #0
beq go

@ get sum of partial multiplications depending on flag values:

first:
add r3, r3, r1
and r3, r3, #0xFFFEFFFF
b go

second:
add r3, r3, r5 
and r3, r3, #0xFFFEFFFF

@ analysis of the moved bit and saving it on the stack:

go:
tst r3, #1
beq stek
mov r7, #1
b push

stek:
mov r7, #0

push:
stmfd sp!, {r7}

@ increase the counter r0:
add r0, r0, #1

@ move the mask:
mov r4, r4, lsl #1

@ transfer the value of the moved bit to r6 for further analysis of the multiplier:
mov r6, r8

@ do the arithmetic shift of the sum of partial multiplications to the right by a bit:
mov r3, r3, lsr #1
tst r3, #16384
beq jump
add r3, r3, #32768

jump:
mov r8, #0

@ checking the mask to exit the cycle:

cmp r4, #32768
beq out_cycle
b compare

out_cycle:
mov r8, #0

@ exit values from the stack. Preparation of the register of the sum of partial multiplications:

out:
cmp r8, r0
beq check_sign
mov r3, r3, lsl #1
ldmfd r13!, {r5}
add r3, r3, r5
add r8, r8, #1
b out

@ check the sign of the final multiplication:

check_sign:
cmp r10, #1
beq invert
b finish

invert: 
add r3, r3, #0x80000000

@ end:

finish: .end