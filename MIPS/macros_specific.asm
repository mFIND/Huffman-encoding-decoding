	.include "macros.asm"
################################################################################################################################################
	.macro GET_FILE_PATH (%str1, %fileloc, %size, %end, %endExpl_1, %endExpl_2)
	ori	$v0, $0, 54
	la	$a0, %str1
	la	$a1, %fileloc
	ori	$a2, $0, %size
	syscall
	
	beq	$a1, -2, %end
	beq	$a1, -3, %endExpl_1
	beq	$a1, -4, %endExpl_2
	.end_macro
################################################################################################################################################
	.macro PRINT_BUFFER (%addressOfBuff)
	ori	$v0, $0, 4
	la	$a0, %addressOfBuff
	syscall
	.end_macro
################################################################################################################################################
	.macro READ_FROM_FILE(%filename, %tempbuff, %size, %inputted, %endExpl_3)
	ori	$v0, $0, 14						# read from file
	ori	$a0, %filename, 0
	la	$a1, %tempbuff
	or	$a2, $0, %size
	syscall
	beqz	$v0, %inputted					# file malfunction (too short)
	bltz	$v0, %endExpl_3					# EOF
	.end_macro
################################################################################################################################################
	.macro PREPARE_PREHEADER(%outputbuff, %reg)
	sw	$0, %outputbuff(%reg)
	addiu	%reg, %reg, 4
	subu	$t5, $s0, $s1
	sw	$t5, %outputbuff(%reg)
	addiu	%reg, %reg, 4
	.end_macro
################################################################################################################################################
	.macro GENERATE_CODES_AND_FILE_HEADER(%descriptor, %outputbuff)
	xor	$t9, $t9, $t9					# $t9 - code length
								# code starting with 1 - 1 ASCIICOD
								# code starting with 0 - 0 TREE
	xor	$t8, $t8, $t8					# $t8 - code
	ori	$t7, $s2, 0						# $t7 - pointer (root at beginning)
	
	xor	$t4, $t4, $t4					# $t4 - temporary register
	xor	$t3, $t3, $t3					# $t3 - number of bits in $t4
	xor	$t2, $t2, $t2					# $t2 - number of bytes in outputbuff
	PREPARE_PREHEADER(%outputbuff, $t2)
	
	ori	$t1, $0, 1
	sll	$t1, $t1, 8						# $t1 - bit starting bare ascii code
	jal	GENERATION
	b	ENDGENERATION
INPUT_TO_BUFFER:
	addiu	$t3, $t3, -8
	srlv	$t5, $t4, $t3					# moving $t4 right to fit highest bites in lowest 8
	sb	$t5, %outputbuff($t2)					# aand save
	addiu	$t2, $t2, 1
	addiu	$t5, $t3, -8
	bgez	$t5, INPUT_TO_BUFFER
	jr	$ra
# # # # # # # # # # # # # # # # # # 
GENERATION:
								# ENTER_PREPARE_STACK.FRAME_POINTERS
	sw	$fp, -4($sp)
    	sw	$ra, -8($sp)
    	addiu	$fp, $sp, -4
    	addiu	$sp, $sp, -16
    	
  	addiu	$t9, $t9, 1
  	sw	$t7,  -8($fp)
  	sw	$t8, -12($fp)
	bgeu	$t7, $s1, ENTERCODETOLETTER				# if i'm above nodes
	
	addiu	$t3, $t3, 1						# what we know about $t4 (number of bits)
	sll	$t4, $t4, 1						# preparing header
	addiu	$t6, $t3, -8
	bgezal	$t6, INPUT_TO_BUFFER
	
	sll	$t8, $t8, 1
	lw	$t7, 0($t7)
	jal	GENERATION
	ori	$t8, $t8, 1
	lw	$t7, -8($fp)
	lw	$t7, 4($t7)
	jal	GENERATION
	b	EXIT
ENTERCODETOLETTER:
	addiu	$t3, $t3, 9						# number of bits in $t4
	sll	$t4, $t4, 9
	or	$t4, $t4, $t1
	lbu	$t6, 7($t7)						# $t6 - contains ASCII char
	or	$t4, $t4, $t6					# $t4 - contains leaf
	addiu	$t5, $t3, -8
	bgezal	$t5, INPUT_TO_BUFFER
	
	bgtu	$t9, maxCodeLen, BARECODE
	
	beqz	$t8, CODEWITH_1_ATEND					# way to distinguish 00000000 (end of file) from 00000000(1) letter code
	sb	$t9, 6($t7)
	sh	$t8, 4($t7)
	b	EXIT
CODEWITH_1_ATEND:
	addiu	$t9, $t9, 1						# normal code: 0 + code
	sb	$t9, 6($t7)						# special code: 1 + ASCII CODE
	addiu	$t9, $t9, -1
	sll	$t8, $t8, 1
	ori	$t8, $t8, 1
	sh	$t8, 4($t7)
	b	EXIT
BARECODE:
	ori	$t8, $t1, 0
	or	$t8, $t8, $t6
	sh	$t8, 4($t7)
	ori	$t6, $0, 9
	sb	$t6, 6($t7)
EXIT:
	lw	$t8, -12($fp)
	lw	$t7, -8($fp)
	addiu	$t9, $t9, -1
	addiu	$sp, $sp, 8
								# EXIT_PREPARE_STACK.FRAME_POINTERS
	lw	$ra, -4($fp)
   	lw	$fp, ($fp)
   	addiu	$sp, $sp, 8
   	jr	$ra
# # # # # # # # # # # # # # # # # # 
ENDGENERATION:
	beqz	$t3, DEFINITIVEENDGENERATION
	ori	$t6, $0, 8						# we need to save rest from $t4 to %outputbuff
	subu	$t3, $t6, $t3
	sllv	$t4, $t4, $t3
	sb	$t4, %outputbuff($t2)					# aand save
	addiu	$t2, $t2, 1
DEFINITIVEENDGENERATION:
	ori	$v0, $0, 15
	ori	$a0, %descriptor, 0
	la	$a1, %outputbuff
	ori	$a2, $t2, 0
	syscall
	.end_macro
################################################################################################################################################
################################################################################################################################################
################################################################################################################################################
		# this is there ONLY because we might want to generate codes in decoder section of the program
		# however this is not used at the moment of v1.005
	.macro GENERATE_CODES
	.text
	xor	$t9, $t9, $t9					# $t9 - code length
	addiu	$t9, $t9, 1						# code starting with 1 - 1 ASCIICOD
								# code starting with 0 - 0 TREE
	xor	$t8, $t8, $t8					# $t8 - code
	ori	$t7, $s2, 0						# $t7 - pointer (root at beginning)
	xor	$t6, $t6, $t6
	addiu	$t6, $t6, -1
	ori	$t1, $0, 1						# $t1 - code length when BARECODE (bare ascii code)
	jal	GENERATION
	b	ENDGENERATION
# # # # # # # # # # # # # # # # # # 
GENERATION:
								# ENTER_PREPARE_STACK.FRAME_POINTERS
	sw	$fp, -4($sp)
    	sw	$ra, -8($sp)
    	addiu	$fp, $sp, -4
    	addiu	$sp, $sp, -8
		
	addiu	$sp, $sp, -8
  	addiu	$t9, $t9, 1
  	sw	$t7,  -8($fp)
  	sw	$t8, -12($fp)
  	
	bgeu	$t7, $s1, ENTERCODETOLETTER				# if i'm above nodes
	sll	$t8, $t8, 1
	lw	$t7, 0($t7)
	jal	GENERATION
	ori	$t8, $t8, 1
	lw	$t7, -8($fp)
	lw	$t7, 4($t7)
	jal	GENERATION
	b	EXIT
ENTERCODETOLETTER:
	bgtu	$t9, maxCodeLen, BARECODE
	beqz	$t8, CODEWITH_1_ATEND					# way to distinguish 00000000 (end of file) from 00000000(1) letter code
	sb	$t9, 6($t7)
	sh	$t8, 4($t7)
	b	EXIT
CODEWITH_1_ATEND:
	addiu	$t9, $t9, 1						# normal code: 0 + code
	sb	$t9, 6($t7)						# special code: 1 + ASCII CODE
	addiu	$t9, $t9, -1
	sll	$t8, $t8, 1
	ori	$t8, $t8, 1
	sh	$t8, 4($t7)
	b	EXIT
BARECODE:
	sll	$t8, $t1, 8
	lbu	$t6, 7($t7)
	or	$t8, $t8, $t6
	sh	$t8, 4($t7)
	ori	$t6, $0, 9
	sb	$t6, 6($t7)
EXIT:
	lw	$t8, -12($fp)
	lw	$t7, -8($fp)
	addiu	$t9, $t9, -1
	addiu	$sp, $sp, 8
								# EXIT_PREPARE_STACK.FRAME_POINTERS
	lw	$ra, -4($fp)
   	lw	$fp, ($fp)
   	addiu	$sp, $sp, 8
   	jr	$ra
# # # # # # # # # # # # # # # # # # 
ENDGENERATION:
	.end_macro
################################################################################################################################################
