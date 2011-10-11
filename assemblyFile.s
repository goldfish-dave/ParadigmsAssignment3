.text
.global mymin
.type mymin, @function
.p2align 4,,15

mymin:

pushq	%rbp

movq	%rsp, %rbp

pushq	%rbx

# allocate memory
movq	%rdi, %rax
imulq	$4, %rax, %rax
addq $16, %rax
imulq $4, %rax, %rax
subq %rax, %rsp
andq $-16, %rsp

#create a constant, put in xmm2
#leaq $.const<10.0>, %xmm2

### function body ###

# load paramters
#movq %rdi, %rax
#movq %rsi, %r10
#movq %rdx, %r11



# assign shit to an ident, c = a
movq %rsi, %rax
movq %rcx, %r10

movq %rdi, %rbx
shl $2, %rbx
jz loop_end

loop_begin:

movaps (%rax), %xmm0
movaps %xmm0, (%r10)

addq $16, %rax
addq $16, %r10
decq %rbx
jnz loop_begin

loop_end:

# add shit together, c = c + a
movq %rsi, %rax
movq %rcx, %r10
movq %rcx, %r11

movq %rdi, %rbx
shrq $2, %rbx
jz loop_end

loop_begin:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#addition
addps %xmm0, %xmm1

movaps %xmm1, (%r11)

#if rax == const etc.
addq $16, %rax
addq $16, %r11
decq %rbx
jnz loop_begin

loop_end:


# function epilogue
popq	%rbx
leave
ret

.data
.align 16
/*.const 10.0:
	.float 10.0
	.float 10.0
	.float 10.0
	.float 10.0
*/
