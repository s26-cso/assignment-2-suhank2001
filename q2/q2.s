.text
    .globl main

main:
    # Frame setup: save RA and s-registers (callee-saved) to survive library calls
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    sd      s3, 24(sp)
    sd      s4, 16(sp)
    sd      s5,  8(sp)

    # Calculate n = argc - 1 and save argv pointer
    addi    s0, a0, -1          
    mv      s5, a1              

    beqz    s0, exit_clean      

    # Allocate arr[n] (4 bytes per element)
    slli    a0, s0, 2           
    call    malloc
    mv      s1, a0              

    # Allocate result[n] and initialize entries to -1
    slli    a0, s0, 2
    call    malloc
    mv      s2, a0              

    sd      zero, 0(sp)         # Store loop counter i on stack to avoid clobbering
init_loop:
    ld      t0, 0(sp)           
    bge     t0, s0, init_done
    slli    t1, t0, 2
    add     t1, s2, t1
    li      t2, -1
    sw      t2, 0(t1)           # result[i] = -1
    addi    t0, t0, 1
    sd      t0, 0(sp)
    j       init_loop
init_done:

    # Allocate stack space for indices (stk[n])
    slli    a0, s0, 2
    call    malloc
    mv      s3, a0              
    li      s4, -1              # stktop = -1 (indicates empty stack)

    # Parse command line arguments (strings) into integers
    sd      zero, 0(sp)         
parse_loop:
    ld      t0, 0(sp)           
    bge     t0, s0, parse_done
    addi    t1, t0, 1           
    slli    t1, t1, 3           # 8-byte offset for 64-bit pointers in argv
    add     t1, s5, t1
    ld      a0, 0(t1)           # Load argv[i+1]
    call    atoi
    ld      t0, 0(sp)           
    slli    t1, t0, 2
    add     t1, s1, t1
    sw      a0, 0(t1)           # arr[i] = atoi(argv[i+1])
    addi    t0, t0, 1
    sd      t0, 0(sp)
    j       parse_loop
parse_done:

    # Main logic: Right-to-left pass to find Next Greater Element
    addi    t0, s0, -1
    sd      t0, 0(sp)           # i = n - 1

stack_loop:
    ld      t0, 0(sp)           
    bltz    t0, stack_done

    slli    t1, t0, 2
    add     t1, s1, t1
    lw      t1, 0(t1)           # t1 = current element arr[i]

pop_loop:
    # Pop from stack if stack not empty and top element is <= current
    bltz    s4, pop_done
    slli    t2, s4, 2
    add     t2, s3, t2
    lw      t2, 0(t2)           # t2 = index stored at stack top
    slli    t3, t2, 2
    add     t3, s1, t3
    lw      t3, 0(t3)           # t3 = arr[stk_top]
    bgt     t3, t1, pop_done    # Stop if we find a strictly greater element
    addi    s4, s4, -1          # Pop stack
    j       pop_loop
pop_done:

    # If stack is not empty, top element is the next greater element
    ld      t0, 0(sp)
    bltz    s4, do_push
    slli    t2, s4, 2
    add     t2, s3, t2
    lw      t2, 0(t2)           
    slli    t3, t0, 2
    add     t3, s2, t3
    sw      t2, 0(t3)           # result[i] = stk_top_index

do_push:
    # Push current index onto the monotonic stack
    ld      t0, 0(sp)
    addi    s4, s4, 1
    slli    t2, s4, 2
    add     t2, s3, t2
    sw      t0, 0(t2)           

    addi    t0, t0, -1
    sd      t0, 0(sp)
    j       stack_loop
stack_done:

    # Print the result array space-separated
    sd      zero, 0(sp)         

print_loop:
    ld      t0, 0(sp)
    bge     t0, s0, print_newline

    beqz    t0, no_space
    la      a0, fmt_space
    call    printf
no_space:
    ld      t0, 0(sp)
    slli    t1, t0, 2
    add     t1, s2, t1
    lw      a1, 0(t1)           # Load result[i] for printf
    la      a0, fmt_int
    call    printf

    ld      t0, 0(sp)
    addi    t0, t0, 1
    sd      t0, 0(sp)
    j       print_loop

print_newline:
    la      a0, fmt_newline
    call    printf

exit_clean:
    # Epilogue: Restore stack pointer and return
    li      a0, 0
    ld      ra, 56(sp)
    ld      s0, 48(sp)
    ld      s1, 40(sp)
    ld      s2, 32(sp)
    ld      s3, 24(sp)
    ld      s4, 16(sp)
    ld      s5,  8(sp)
    addi    sp, sp, 64
    ret

    .section .rodata
fmt_int:     .string "%d"
fmt_space:   .string " "
fmt_newline: .string "\n"
