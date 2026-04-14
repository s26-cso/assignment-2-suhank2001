.section .rodata
filename: .string "input.txt"
yes_str:  .string "Yes\n"
no_str:   .string "No\n"
mode_r:   .string "r"

.text
.globl main

main:
    addi sp, sp, -48
    sd   ra, 40(sp)
    sd   s0, 32(sp)   # FILE*
    sd   s1, 24(sp)   # effective file size n (after newline strip)
    sd   s2, 16(sp)   # loop index i
    sd   s3,  8(sp)   # n/2  (loop bound)

    # --- Open file ---
    la   a0, filename
    la   a1, mode_r
    call fopen
    mv   s0, a0
    beq  s0, x0, print_no    # fopen failed -> treat as not palindrome

    # --- Seek to end, read size ---
    mv   a0, s0
    li   a1, 0
    li   a2, 2                # SEEK_END
    call fseek
    mv   a0, s0
    call ftell
    mv   s1, a0               # s1 = raw byte count

    # --- Strip trailing newline if present ---
    # Seek to last byte and peek at it
    mv   a0, s0
    addi a1, s1, -1           # offset = size - 1
    li   a2, 0                # SEEK_SET
    call fseek
    mv   a0, s0
    call fgetc                # a0 = last char (or EOF if size was 0)
    li   t0, 10               # '\n'
    bne  a0, t0, .Lno_strip
    addi s1, s1, -1           # shrink effective size by 1
.Lno_strip:

    # --- Edge case: empty (or all-newline) file is a palindrome ---
    blez s1, print_yes

    # --- Prepare loop: i = 0, bound = n/2 ---
    li   s2, 0
    srli s3, s1, 1            # s3 = floor(n/2)

    # --- Main loop: compare s[i] vs s[n-1-i] for i in [0, n/2) ---
check_loop:
    bge  s2, s3, print_yes    # exhausted all pairs -> palindrome

    # Read s[i]
    mv   a0, s0
    mv   a1, s2               # offset = i
    li   a2, 0                # SEEK_SET
    call fseek
    mv   a0, s0
    call fgetc
    mv   t0, a0               # t0 = s[i]

    # Read s[n-1-i]
    mv   a0, s0
    sub  a1, s1, s2           # n - i
    addi a1, a1, -1           # n - 1 - i
    li   a2, 0                # SEEK_SET
    call fseek
    mv   a0, s0
    call fgetc
    mv   t1, a0               # t1 = s[n-1-i]

    # If mismatch, not a palindrome
    bne  t0, t1, print_no

    addi s2, s2, 1            # i++
    j    check_loop

print_yes:
    la   a0, yes_str
    call printf
    j    done

print_no:
    la   a0, no_str
    call printf

done:
    beq  s0, x0, .Lskip_close
    mv   a0, s0
    call fclose               # close file
.Lskip_close:
    li   a0, 0
    ld   ra, 40(sp)
    ld   s0, 32(sp)
    ld   s1, 24(sp)
    ld   s2, 16(sp)
    ld   s3,  8(sp)
    addi sp, sp, 48
    ret
