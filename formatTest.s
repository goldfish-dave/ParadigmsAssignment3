####Function Definitions####

.text
.global mymin
.type mymin, @function
.p2align 4,,15

mymin:

pushq %rbp
movq %rsp, %rbp
pushq %rbx

####Creating memory for local variables####

movq %rdi, %rax
imulq $4, %rax, %rax
addq $16, %rax
imulq $13, %rax, %rax
subq %rax, %rsp
andq $-16, %rsp

####Function body####

##suffix '.' means temporary variable used for linearisation##
##.9 = a + b##

movq %rdi, %r11
imulq $4, %r11, %r11
addq $16, %r11
imulq $208, %r11, %r11
subq %rbp, %r11
negq %r11
andq $-16, %r11
movq %rsi, %rax
movq %rdx, %r10

movq %rdi, %rbx
shrq $2, %rbx
jz .loop_end0

.loop_begin0:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#operation
mulps %xmm0, %xmm1

movaps %xmm1, (%r11)

addq $16, %rax
addq $16, %r11
decq %rbx
jnz .loop_begin0

.loop_end0:

##.8 = a + b##

movq %rdi, %r11
imulq $4, %r11, %r11
addq $16, %r11
imulq $192, %r11, %r11
subq %rbp, %r11
negq %r11
andq $-16, %r11
movq %rsi, %rax
movq %rdx, %r10

movq %rdi, %rbx
shrq $2, %rbx
jz .loop_end1

.loop_begin1:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#operation
mulps %xmm0, %xmm1

movaps %xmm1, (%r11)

addq $16, %rax
addq $16, %r11
decq %rbx
jnz .loop_begin1

.loop_end1:

##c = .9 + .8##
movq %rcx, %r11

movq %rdi, %rax
imulq $4, %rax, %rax
addq $16, %rax
imulq $208, %rax, %rax
subq %rbp, %rax
negq %rax
andq $-16, %rax

movq %rdi, %r10
imulq $4, %r10, %r10
addq $16, %r10
imulq $192, %r10, %r10
subq %rbp, %r10
negq %r10
andq $-16, %r10

movq %rdi, %rbx
shrq $2, %rbx
jz .loop_end2

.loop_begin2:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#operation
addps %xmm0, %xmm1

movaps %xmm1, (%r11)

addq $16, %rax
addq $16, %r11
decq %rbx
jnz .loop_begin2

.loop_end2:

##x = 20##
#assign #1 variable to %r10

movq %rdi, %r10
imulq $4, %r10, %r10
addq $16, %r10
imulq $16, %r10, %r10
subq %rbp, %r10
negq %r10
andq $-16, %r10
leaq .const20.0, %rax

movq %rdi, %rbx
shl $2, %rbx
jz .loop_end3

.loop_begin3:

movaps (%rax), %xmm0
movaps %xmm0, (%r10)

#line "addq $16, %rax" removed because RHS is a constant

addq $16, %r10
decq %rbx
jnz .loop_begin3

.loop_end3:

##c = 100 + 40##
movq %rcx, %r11
leaq .const100.0, %rax
leaq .const40.0, %r10

movq %rdi, %rbx
shrq $2, %rbx
jz .loop_end4

.loop_begin4:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#operation
addps %xmm0, %xmm1

movaps %xmm1, (%r11)

#line "addq $16, %rax" removed because the source is a constant
addq $16, %r11
decq %rbx
jnz .loop_begin4

.loop_end4:

####Function Epilogue####

popq	%rbx
leave
ret

.data
.align 16
.const20.0:
	.float 20.0
	.float 20.0
	.float 20.0
	.float 20.0
.const100.0:
	.float 100.0
	.float 100.0
	.float 100.0
	.float 100.0
.const40.0:
	.float 40.0
	.float 40.0
	.float 40.0
	.float 40.0
