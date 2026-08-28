addi $t0, $zero, 5
addi $t1, $zero, 10
add  $t2, $t0, $t1
sw   $t2, 0($zero)
lw   $t3, 0($zero)
beq  $t3, $t2, skip
addi $t4, $zero, 99
addi $t5, $zero, 55

skip:

