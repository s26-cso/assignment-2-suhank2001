.text

# --- make_node(int val) ---
# Allocates 24 bytes (4:val, 4:padding, 8:left, 8:right)
# Returns: a0 = pointer to new node
# --------------------------
    .globl make_node
make_node:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)
    mv      s0, a0              # Save input val

    li      a0, 24              # Node size: 4(int)+4(pad)+8(ptr)+8(ptr)
    call    malloc

    sw      s0, 0(a0)           # Set val
    sd      zero, 8(a0)         # left = NULL
    sd      zero, 16(a0)        # right = NULL

    ld      ra, 8(sp)
    ld      s0, 0(sp)
    addi    sp, sp, 16
    ret

# --- insert(Node* root, int val) ---
# Recursive BST insertion. Ignores duplicates.
# Returns: a0 = root of tree
# -----------------------------------
    .globl insert
insert:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)          # s0 = current root
    sd      s1, 8(sp)           # s1 = target val
    mv      s0, a0
    mv      s1, a1

    # Base Case: create node if current root is null
    bne      s0, zero, insert_notnull
    mv      a0, s1
    call    make_node
    j       insert_done

insert_notnull:
    lw      t0, 0(s0)           # t0 = current root value
    blt     s1, t0, insert_left
    bgt     s1, t0, insert_right
    mv      a0, s0              # Duplicate found: return current root
    j       insert_done

insert_left:
    ld      a0, 8(s0)           # Load root->left
    mv      a1, s1
    call    insert
    sd      a0, 8(s0)           # Update root->left with result
    mv      a0, s0
    j       insert_done

insert_right:
    ld      a0, 16(s0)          # Load root->right
    mv      a1, s1
    call    insert
    sd      a0, 16(s0)          # Update root->right with result
    mv      a0, s0

insert_done:
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    addi    sp, sp, 32
    ret

# --- get(Node* root, int val) ---
# Searches for val in BST.
# Returns: a0 = Node pointer or NULL
# --------------------------------
    .globl get
get:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1, 8(sp)
    mv      s0, a0
    mv      s1, a1

    # Base Case: Not found
    bne     s0, zero, get_notnull
    li      a0, 0
    j       get_done

get_notnull:
    lw      t0, 0(s0)
    blt     s1, t0, get_left
    bgt     s1, t0, get_right
    mv      a0, s0              # Match found
    j       get_done

get_left:
    ld      a0, 8(s0)
    mv      a1, s1
    call    get
    j       get_done

get_right:
    ld      a0, 16(s0)
    mv      a1, s1
    call    get

get_done:
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    addi    sp, sp, 32
    ret

# --- getAtMost(int val, Node* root) ---
# Finds max value in tree such that value <= limit.
# Returns: a0 = max value or -1
# --------------------------------------
    .globl getAtMost
getAtMost:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)          # s0 = limit val
    sd      s1, 8(sp)           # s1 = current root
    mv      s0, a0
    mv      s1, a1

    # Base Case: Empty subtree
    bne     s1, zero, gam_notnull
    li      a0, -1
    j       gam_done

gam_notnull:
    lw      t0, 0(s1)           # t0 = current val

    # If current > limit, max must be in left subtree
    bgt     t0, s0, gam_go_left 

    # If current <= limit, current is a candidate. Check right subtree for better.
    mv      a0, s0
    ld      a1, 16(s1)          
    call    getAtMost
    
    # If right subtree finds nothing better (returns -1), use current root
    blt     a0, zero, gam_use_root
    j       gam_done            

gam_use_root:
    lw      a0, 0(s1)           
    j       gam_done

gam_go_left:
    mv      a0, s0
    ld      a1, 8(s1)           
    call    getAtMost

gam_done:
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    addi    sp, sp, 32
    ret