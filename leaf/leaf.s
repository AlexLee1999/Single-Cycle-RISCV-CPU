.data
    a: .word -1
    b: .word -1
    c: .word 0
    d: .word -1
.text
.globl __start

leaf:
    add x5, x10, x11
    add x6, x12, x13
    sub x20, x5, x6
    addi x10, x20, 0
    jalr x0, 0(x1)
    
__start:
    la t0, a
    lw x10, 0(t0)
    la t0, b
    lw x11, 0(t0)
    la t0, c
    lw x12, 0(t0)
    la t0, d
    lw x13, 0(t0)
    jal x1, leaf
    la t0, d
    sw x10, 4(t0)
    addi a0, x0, 10
    ecall