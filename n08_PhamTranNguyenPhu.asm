.data
    infix:      .asciiz "9+2+8*6"
    postfix:    .space 100
    msg_result: .asciiz "Gia tri cua bieu thuc: "

.text
main:
    # Chuy?n ??i bi?u th?c trung t? sang h?u t?
    la   $a0, infix          # T?i ??a ch? bi?u th?c trung t?
    la   $a1, postfix        # T?i ??a ch? ?? l?u bi?u th?c h?u t?
    jal  infixToPostfix      # G?i h�m chuy?n ??i
    
    # T�nh gi� tr? bi?u th?c h?u t?
    la   $a0, postfix        # T?i ??a ch? bi?u th?c h?u t?
    jal  evaluatePostfix     # G?i h�m t�nh gi� tr?
    
    # In k?t qu?
    li   $v0, 4              # Syscall ?? in chu?i
    la   $a0, msg_result     # T?i chu?i "Gia tri cua bieu thuc: "
    syscall
    
    li   $v0, 1              # Syscall ?? in s? nguy�n
    move $a0, $v1            # Gi� tr? k?t qu? (l?u trong $v1)
    syscall
    
    li   $v0, 10             # Tho�t
    syscall

# H�m chuy?n ??i trung t? sang h?u t?
infixToPostfix:
    la   $t0, 0($a0)         # ??a ch? bi?u th?c trung t?
    la   $t1, 0($a1)         # ??a ch? ?? l?u bi?u th?c h?u t?
    la   $t2, 0x10010000     # Stack ?? l?u to�n t?
    addi $sp, $sp, -4        # Kh?i t?o stack

convert_loop:
    lb   $t3, 0($t0)         # ??c k� t? ti?p theo
    beq  $t3, $zero, end_convert_loop # N?u l� k� t? null th� k?t th�c
    
    # N?u l� s?, sao ch�p v�o bi?u th?c h?u t?
    blt  $t3, '0', check_operator
    bgt  $t3, '9', check_operator
    sb   $t3, 0($t1)
    addi $t1, $t1, 1
    j    next_char

check_operator:
    # N?u l� to�n t?, x? l� ?? ?u ti�n
    beq  $t3, '(', push_operator
    beq  $t3, ')', close_parenthesis

    # X? l� c�c to�n t? kh�c
    handle_operator:
    lw   $t4, 0($sp)         # L?y to�n t? tr�n c�ng c?a stack
    beq  $t4, $zero, push_operator

    # Ki?m tra ?? ?u ti�n
    li   $t5, 1              # ?? ?u ti�n c?a + v� -
    li   $t6, 2              # ?? ?u ti�n c?a * v� /
    beq  $t3, '+', check_priority
    beq  $t3, '-', check_priority
    move $t5, $t6
    beq  $t3, '*', check_priority
    beq  $t3, '/', check_priority

check_priority:
    lw   $t7, 0($sp)
    beq  $t7, '(', push_operator
    beq  $t7, $zero, push_operator
    li   $t8, 1              # ?? ?u ti�n c?a + v� -
    li   $t9, 2              # ?? ?u ti�n c?a * v� /
    beq  $t7, '+', compare_priority
    beq  $t7, '-', compare_priority
    move $t8, $t9
    beq  $t7, '*', compare_priority
    beq  $t7, '/', compare_priority

compare_priority:
    bge  $t8, $t5, pop_operator

push_operator:
    addi $sp, $sp, -4
    sw   $t3, 0($sp)
    j    next_char

pop_operator:
    lw   $t4, 0($sp)
    addi $sp, $sp, 4
    sb   $t4, 0($t1)
    addi $t1, $t1, 1
    j    handle_operator

close_parenthesis:
    lw   $t4, 0($sp)
    beq  $t4, '(', next_char
    addi $sp, $sp, 4
    sb   $t4, 0($t1)
    addi $t1, $t1, 1
    j    close_parenthesis

next_char:
    addi $t0, $t0, 1
    j    convert_loop

end_convert_loop:
    lw   $t4, 0($sp)
    beq  $t4, $zero, end_convert
    addi $sp, $sp, 4
    sb   $t4, 0($t1)
    addi $t1, $t1, 1
    j    end_convert_loop

end_convert:
    sb   $zero, 0($t1)       # K?t th�c chu?i h?u t?
    jr   $ra

# H�m t�nh gi� tr? bi?u th?c h?u t?
evaluatePostfix:
    la   $t0, 0($a0)         # ??a ch? bi?u th?c h?u t?
    la   $t1, 0x10010000     # Kh?i t?o Stack Pointer t?i ??a ch? an to�n
    
eval_loop:
    lb   $t2, 0($t0)         # ??c k� t? ti?p theo
    beq  $t2, $zero, end_eval_loop # N?u l� k� t? null th� k?t th�c
    
    # N?u l� s?, ??y v�o stack
    blt  $t2, '0', check_eval_operator
    bgt  $t2, '9', check_eval_operator
    
    sub  $t2, $t2, '0'       # Chuy?n ??i k� t? th�nh s?
    sw   $t2, 0($t1)
    addi $t1, $t1, 4
    j    next_eval_char
    
check_eval_operator:
    # X? l� to�n t?
    addi $t1, $t1, -4
    lw   $t3, 0($t1)         # Pop op2
    addi $t1, $t1, -4
    lw   $t4, 0($t1)         # Pop op1
    
    # Th?c hi?n ph�p to�n
    beq  $t2, '+', eval_add
    beq  $t2, '-', eval_sub
    beq  $t2, '*', eval_mul
    beq  $t2, '/', eval_div
    
eval_add:
    add  $t5, $t4, $t3
    j    eval_push_result
eval_sub:
    sub  $t5, $t4, $t3
    j    eval_push_result
eval_mul:
    mul  $t5, $t4, $t3
    j    eval_push_result
eval_div:
    div  $t4, $t3
    mflo $t5
    j    eval_push_result

eval_push_result:
    sw   $t5, 0($t1)
    addi $t1, $t1, 4
    
next_eval_char:
    addi $t0, $t0, 1
    j    eval_loop

end_eval_loop:
    addi $t1, $t1, -4
    lw   $v1, 0($t1)         # L?y k?t qu? cu?i c�ng
    jr   $ra
