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

####Code body####

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
jz .loop_end0

.loop_begin0:

movaps (%rax), %xmm0
movaps %xmm0, (%r10)

#line "addq $16, %rax" removed because RHS is a constant

addq $16, %r10
decq %rbx
jnz .loop_begin0

.loop_end0:

##c = x##

movq %rcx, %r10
#assign #1 variable to %rax

movq %rdi, %rax
imulq $4, %rax, %rax
addq $16, %rax
imulq $16, %rax, %rax
subq %rbp, %rax
negq %rax
andq $-16, %rax


movq %rdi, %rbx
shl $2, %rbx
jz .loop_end1

.loop_begin1:

movaps (%rax), %xmm0
movaps %xmm0, (%r10)

addq $16, %rax
addq $16, %r10
decq %rbx
jnz .loop_begin1

.loop_end1:

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
