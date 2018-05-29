# $s0   -   4B after end of data about ASCII count
# $s0   -   4B after end of data about ASCII count
# $s1   -   4B after end of data of tree nodes <-> last data of ASCII count
# $s2   -   4B pointing at root node
# $s3   -   
# $s4   -   for more complex macros(WRITE_TO_FILE, RECREATE_TREE_FROM_FILE)
# $s5   -   
# $s6   -   descriptor of output file
# $s7   -   descriptor of input file

# $sp   -   end of data - tree nodes

	.include "macros_specific.asm"
	
	.eqv	pathToFile	0x80
	.eqv	memorySize	0x800					# size of buffers for text ; > 2056 and dividable by 4
	.eqv	enco_file	0x2					# encoding -> file/user
	.eqv	maxCodeLen	0x8
	
	.data
	
	.align	2
str1:	.asciiz	"Enter path to the input file"
	.align	2
str2:	.asciiz	"Enter path to the output file"
	.align	2
filelocIn:	.space	pathToFile
	.align	2
filelocOut:	.space	pathToFile
	.align	2
inputbuff:	.space	memorySize
	.align	2
outputbuff:	.space	memorySize
	.align	2
letCounter:	.space	1024						# 2^32 for each letter

	.text
	PRINT_STRING_LIT("Enter 0 encode, 1 to decode or any other number to terminate: ")
								# GET_INT_JUMP_CHOICE(encode, decode, endExpl_4)
	li	$v0, 5
	syscall
	bgtu	$v0, 1, endExpl_4
	bnez	$v0, decode
	
####################################
####################################
####################################
	
encode:	
	PRINT_STRING_LIT		(" - - - ENCODER - - -\n")
								# (text, buffer for name, its size, end of programm, error msg 1, error msg 2)
	GET_FILE_PATH		(str1, filelocIn,  pathToFile, end, endExpl_1, endExpl_2)
	la	$t8, filelocIn
	jal	REMOVE__N
	GET_FILE_PATH		(str2, filelocOut, pathToFile, end, endExpl_1, endExpl_2)
	la	$t8, filelocOut
	jal	REMOVE__N
								# open file, jump if error opening file
	OPEN_FILE			(filelocIn, 0, 000, endExpl_3)
	ori	$s7, $v0, 0						# descriptor of input file
	
	PRINT_STRING_LIT		("Counting letters...\n")
letter_counter:
								# (%filename, %tempbuff, %size, %inputted, %endExpl_3)
	READ_FROM_FILE		($s7, inputbuff, memorySize, whole_input_file_processed, endExpl_3)
								# COUNT_LETTERS(%size, %counterBuff, %letCounter)
	ori	$t9, $v0, 0						# from number of B read to 0 
LOOPCOUNT:
	addiu	$t9, $t9, -1
	lbu	$t8, inputbuff($t9)
	sll	$t8, $t8, 2						# 'muli' 4
	lw	$t7, letCounter($t8)					# problem
	addiu	$t7, $t7, 1
	sw	$t7, letCounter($t8)
	bnez	$t9, LOOPCOUNT
	b letter_counter
whole_input_file_processed:
	CLOSE_FILE			($s7)
	
	
	jal	INSERT_DATA_TO_STACK					# inserts data from buffer
	jal	SORT_UNSIGNED_WORD
	jal	CREATE_TREE						# only nodes
	
	OPEN_FILE			(filelocIn, 0, 000, endExpl_3)
	ori	$s7, $v0, 0
	OPEN_FILE			(filelocOut, 1, 000, endExpl_3)
	ori	$s6, $v0, 0
	
	PRINT_STRING_LIT		("Generating codes...\n")
	
	GENERATE_CODES_AND_FILE_HEADER	($s6, outputbuff)			# generates code for each letter DEBUG ?
	
	
	jal	READ_DATA_FROM_STACK					# writes to letCounter and to file: $s6 (header)
	
	PRINT_STRING_LIT		("Encoding...\n")
	READ_FROM_FILE		($s7, inputbuff, memorySize, encoding_completed, endExpl_3)
encoding_in_progress:
	jal	ENCODE_AND_WRITE_TO_FILE
	BREAK							# ASSERT as of version 1.003
	b encoding_in_progress
encoding_completed:
	
	CLOSE_FILE			($s7)
	CLOSE_FILE			($s6)
	
	b endExpl_5							# success
####################################
####################################
####################################
	
decode:
	PRINT_STRING_LIT		(" - - - DECODER - - -\n")
	
	GET_FILE_PATH		(str1, filelocIn,  pathToFile, end, endExpl_1, endExpl_2)
	la	$t8, filelocIn
	jal	REMOVE__N
	GET_FILE_PATH		(str2, filelocOut, pathToFile, end, endExpl_1, endExpl_2)
	la	$t8, filelocOut
	jal	REMOVE__N
	
	OPEN_FILE			(filelocIn, 0, 000, endExpl_6)		# open file, jump if error opening file
	ori	$s7, $v0, 0
	
	READ_FROM_FILE		($s7, inputbuff, 8, endExpl_3, endExpl_3)
								# CHECK_IF_FILE_IS_CORRECT
	lw	$t9, inputbuff+0
	bnez	$t9, endExpl_6					# MAGIC WOR(L)D - 0
	lw	$t0, inputbuff+4
	
	jal	RECREATE_TREE_FROM_FILE					# INSERT_PROCESSED_DATA_TO_STACK
	
	PRINT_STRING_LIT		("Generating codes... (for display purposes)\n")
	GENERATE_CODES						# if we wanna be pure.... we can run this DEBUG ?
	jal	READ_STATS_FROM_STACK
	
	OPEN_FILE			(filelocOut, 1, 000, endExpl_6)		# open file, jump if error opening file
	ori	$s6, $v0, 0
	
	PRINT_STRING_LIT		("Decoding...\n")
	READ_FROM_FILE		($s7, inputbuff, memorySize, decoding_completed, endExpl_3)	
decoding:
	b	DECODE_AND_WRITE_TO_FILE
	BREAK							# ASSERT
	b decoding
decoding_completed:

	CLOSE_FILE			($s7)
	CLOSE_FILE			($s6)
	
	b endExpl_5							# success (?)
####################################
####################################
####################################

endExpl_6:
	PRINT_STRING_LIT		("Wrong file! / Couldn't open the file!\n")
	b end
endExpl_5:
	PRINT_STRING_LIT		("Everything went well... I think.\n")
	b end
endExpl_4:
	PRINT_STRING_LIT		("User input terminated application!\n")
	b end
endExpl_3:
	PRINT_STRING_LIT		("ERROR in reading/writing file!\n")
	b end
endExpl_2:
	PRINT_STRING_LIT		("Sorry, we allow only 255 letter path to a file!\n")
	b end
endExpl_1:
	PRINT_STRING_LIT		("You didn't enter path to a file!\n")
end:	
	END




################################################################################################################################################
################################################################----FUNKCJE----#################################################################
################################################################################################################################################
REMOVE__N:
	lbu	$t9, ($t8)
	beqz	$t9, ENDREMOVE
	beq	$t9, 0xA, ENDREMOVE_1
	addiu	$t8, $t8, 1
	b	REMOVE__N
ENDREMOVE_1:
	sb	$0, ($t8)
	jr	$ra
ENDREMOVE:
################################################################################################################################################
PRINT_STATS:
		PRINT_INT($t8)
		PRINT_STRING_LIT("  -  ")
		PRINT_INT($t7)
		PRINT_STRING_LIT("  -  ")
		PRINT_INT($t6)
		PRINT_STRING_LIT("  -  ")
		PRINT_INT($t5)
		PRINT_STRING_LIT("  -  ")
		PRINT_INT_HEX($t5)
		PRINT_STRING_LIT("\n")
	jr	$ra
################################################################################################################################################	
INSERT_DATA_TO_STACK:
		PRINT_STRING_LIT("Inserting to stack...\n")
	ori	$s0, $sp, 0
	xor	$t9, $t9, $t9
LOOPINSERT:
	sll	$t8, $t9, 2
	addiu	$t9, $t9, 1
	bgtu	$t9, 256, EXIT_INSERT_DATA_TO_STACK				# can't do different, otherwise: (@down)
	lw	$t7, letCounter($t8)					# now in $t7 we have number of letters $t8 >> 2
	beqz	$t7, LOOPINSERT					# (@up) this will skip all checks
	srl	$t8, $t8, 2
	sb	$t8, -1($sp)					# BBBB -  code, code, count, char
	sw	$t7, -8($sp)
	addiu	$sp, $sp, -8
	ori	$s1, $sp, 0
	b	LOOPINSERT
EXIT_INSERT_DATA_TO_STACK:
	jr	$ra
################################################################################################################################################
SORT_UNSIGNED_WORD:							# insertion sort
		PRINT_STRING_LIT("Sorting...\n")
	ori	$t9, $s0, 0						# $t9 - where to end
EXTLOOPSORT_UW:
	ori	$t8, $s1, 0						# $t8 - current element
	ori	$t0, $s1, 0						# $t0 - max element
	xor	$t5, $t5, $t5					# $t5 - check for number of internal loops
	lw	$t7, 0($t0)						# $t7 - number of max ascii
INTLOOPSORT_UW:
	addiu	$t5, $t5, 1
	lw	$t6, 0($t8)						# $t6 - number of current ascii
	bgeu	$t7, $t6, BRANCH_SORT
	ori	$t0, $t8, 0						# $t0 - new max ascii
	lw	$t7, 0($t0)						# $t7 - new max ascii value
BRANCH_SORT:
	addiu	$t8, $t8, 8
	bltu	$t8, $t9, INTLOOPSORT_UW
	beq	$t5, 1, EXITSORT_UW
	addiu	$t9, $t9, -8
	beq	$t0, $t9, EXTLOOPSORT_UW				# if pointers are equal - no need to memory swap
								# t1, t2, t3, t4, t5 <= they will be changed!
	xor	$t5, $t5, $t5
LOOPSWAP:
	addu	$t3, $t5, $t0 
	addu	$t4, $t5, $t9
	lw	$t1, ($t3)
	lw	$t2, ($t4)
	sw	$t2, ($t3)
	sw	$t1, ($t4)
	addiu	$t5, $t5, 4
	bne	$t5, 8, LOOPSWAP
		
	b	EXTLOOPSORT_UW
EXITSORT_UW:
	jr	$ra
################################################################################################################################################
CREATE_TREE:
		PRINT_STRING_LIT("Creating tree...\n")
								# ( $s0 - $s1 ]   -   letters
								# ( $s1 - $s2 ]   -   nodes
	ori	$a0, $ra, 0
	ori	$t9, $s1, 0						# $t9 - smallest not included letter
	ori	$s2, $s1, 0
	addiu	$t8, $s1, -12					# $t8 - smallest not included node
LOOP_CREATE:
	xor	$t7, $t7, $t7					# $t7 - smallest nr 1 (pointer)
	xor	$t6, $t6, $t6					# $t6 - smallest nr 2 (pointer)
	xor	$t5, $t5, $t5					# $t5 - smallest nr 1 (value)
	xor	$t4, $t4, $t4					# $t4 - smallest nr 2 (value)

	jal	FIND_SMALLEST					# this one should NEVER branch to TREECREATED
	ori	$t7, $a1, 0
	ori	$t5, $a2, 0
	jal	FIND_SMALLEST
	ori	$t6, $a1, 0
	ori	$t4, $a2, 0
	
	addu	$t5, $t5, $t4					# creating node
	sw	$t5,  -4($s2)					# letter count
	sw	$t7,  -8($s2)					# pointer 1 (1 - INDEX)		# ERROR DEBUG TODO ? (zamienic miejscami?)
	sw	$t6, -12($s2)					# POINTER 0 (0 - INDEX)		# ERROR DEBUG TODO ? (zamienic miejscami?)
	addiu	$s2, $s2, -12
	ori	$sp, $s2, 0
	b	LOOP_CREATE
TREE_CREATED:
	ori	$ra, $a0, 0
	jr	$ra
################################################################################################################################################
FIND_SMALLEST:
	xor	$t1, $t1, $t1
	xor	$t2, $t2, $t2
	
	bgeu	$t9, $s0, NOLETTERSLEFT
	lw	$t1, 0($t9)						# letter count
	b	NODECHECK
NOLETTERSLEFT:
	addiu	$t1, $t1, -1
NODECHECK:
	bltu	$t8, $s2, NONODELEFT
	lw	$t2, 8($t8)						# node count
	b	ENDOFCHECK
NONODELEFT:
	addiu	$t2, $t2, -1
ENDOFCHECK:
	bgtu	$t1, $t2, GIVENODE			
	beq	$t1, 0xffffffff, TREE_CREATED				# no nodes/letters left
#GIVELETTER:							# letter is smallest
	ori	$a1, $t9, 0
	ori	$a2, $t1, 0
	addiu	$t9, $t9, 8						# size of letter is 8B
	b	END_FINDSMLLST
GIVENODE:								# node is smallest
	ori	$a1, $t8, 0
	ori	$a2, $t2, 0
	addiu	$t8, $t8, -12					# size of node is 12B
END_FINDSMLLST:
	jr	$ra
################################################################################################################################################
READ_DATA_FROM_STACK:
	ori	$t0, $ra, 0
	ori	$t9, $s0, 0
		PRINT_STRING_LIT("ASCII  -  Count  -  Code length  -  Code\n")
LOOPREADSTACK_DATA:
	lbu	$t8, -1($t9)					# letter ascii
	lbu	$t6, -2($t9)					# code length
	lhu	$t5, -4($t9)					# code
	lw	$t7, -8($t9)					# letter count
	
	jal	PRINT_STATS						# just general stat printer
	
	sll	$t6, $t6, 24
	or	$t5, $t5, $t6					# contains code and code length
	sll	$t8, $t8, 2
	sw	$t5, letCounter($t8)					# BBBB - code length, NULL, code, code
	addiu	$t9, $t9, -8
	bgtu	$t9, $s1, LOOPREADSTACK_DATA
		PRINT_STRING_LIT("ASCII  -  Count  -  Code length  -  Code\n")
	ori	$ra, $t0, 0
	jr	$ra
################################################################################################################################################
READ_STATS_FROM_STACK:	
	ori	$t0, $ra, 0
	ori	$t9, $s0, 0
		PRINT_STRING_LIT("ASCII  -  Count  -  Code length  -  Code\n")
LOOPREADSTACK_STATS:
	lbu	$t8, -1($t9)					# letter ascii
	lbu	$t6, -2($t9)					# code length
	lhu	$t5, -4($t9)					# code
	lw	$t7, -8($t9)					# letter count
	
	jal	PRINT_STATS						# just general stat printer
	
	addiu	$t9, $t9, -8
	bgtu	$t9, $s1, LOOPREADSTACK_STATS
		PRINT_STRING_LIT("ASCII  -  Count  -  Code length  -  Code\n")
	ori	$ra, $t0, 0
	jr	$ra
################################################################################################################################################
ENCODE_AND_WRITE_TO_FILE:
	xor	$t4, $t4, $t4					# $t4 - number of B in outputbuff
	xor	$t3, $t3, $t3					# $t3 - number of bites currently written in $t2
	xor	$t2, $t2, $t2					# $t2 - register <-> buffer
	xor	$t1, $t1, $t1
	addiu	$t1, $t1, -1
	sll	$t1, $t1, 31					# $t1 - bit mask (higherst bit set)
	ori	$t0, $0, 32						# $t0 - length of a register
INTERNAL.SUPER.LOOP.FOR.EDGE.CASES_ENCODE:
	ori	$s4, $v0, 0						# $v0 - (new) buffer length
	xor	$t9, $t9, $t9					# $t9 - input iterator
####################################
LOOPWRITEFILE:
	lbu	$t8, inputbuff($t9)
	addiu	$t9, $t9, 1
	bgtu	$t9, $s4, PROCEDURE_FOR_EDGE_CASES_ENC				# rest from this buffer	
	sll	$t8, $t8, 2
	lw	$t7, letCounter($t8)					# $t7 - code + code length (BBBB - CL,0,C,C)
	srl	$t6, $t7, 24					# $t6 - code length
	sub	$t5, $t0, $t6					# $t5 - how much to shift
	sllv	$t7, $t7, $t5					# $t7 - code (shifted to highest bits)
	srlv	$t7, $t7, $t5					# $t7 - code (shifted to lowest bits, highest bits cleared)
	
LOOP_WRITE_TO_FILE:
	sllv	$t2, $t2, $t6					# prepare place for code
	addu	$t3, $t3, $t6					# number of bites written to $t2 in a second
	or	$t2, $t2, $t7					# insert code
	bltu	$t3, 8, LOOPWRITEFILE

SAVE_TO_BUFF_IF_POSSIBLE_ENCODE:
								# free to use: $t8, $t7, $t6, $t5
	addiu	$t3, $t3, -8
	srlv	$t8, $t2, $t3					# save last 8 bit to new buffer for save
	sb	$t8, outputbuff($t4)					# save
	addiu	$t4, $t4, 1						# save location
	bgeu	$t4, memorySize, WRITE_TO_FILE_ENCODE			# if end of buffer.. or end of message
	bgeu	$t3, 8, SAVE_TO_BUFF_IF_POSSIBLE_ENCODE
	b	LOOPWRITEFILE	

WRITE_TO_FILE_ENCODE:
	ori	$v0, $0, 15
	ori	$a0, $s6, 0
	la	$a1, outputbuff
	ori	$a2, $t4, 0
	syscall							# ten syscall NIE ZMIENIA zawartosci rejestrow $t0-9
	blt	$v0, 0, endExpl_3					# if error
	xor	$t4, $t4, $t4
	b	LOOPWRITEFILE

PROCEDURE_FOR_EDGE_CASES_ENC:						# it could be end of input file
								# but it as well might be only end
								# of first input segment
		READ_FROM_FILE($s7, inputbuff, memorySize, END_OF_EVERYTHING_SAVE_EVERYTHING_ENCODE, endExpl_3)
	b	INTERNAL.SUPER.LOOP.FOR.EDGE.CASES_ENCODE
	
END_OF_EVERYTHING_SAVE_EVERYTHING_ENCODE:
	ori	$t6, $0, 8
	subu	$t3, $t6, $t3
	sllv	$t8, $t2, $t3					# shifts rest of bits to the left
	sb	$t8, outputbuff($t4)
	addiu	$t4, $t4, 1
	sb	$0,  outputbuff($t4)					# end with NULL just for good measure
	addiu	$t4, $t4, 1
	sb	$0,  outputbuff($t4)					# end with NULL just for good measure
	addiu	$t4, $t4, 1
ACTUALLYWRITE_ENCODE:
	ori	$v0, $0, 15
	ori	$a0, $s6, 0
	la	$a1, outputbuff
	ori	$a2, $t4, 0
	syscall							# ten syscall NIE ZMIENIA zawartosci rejestrow $t0-9
	blt	$v0, 0, endExpl_3					# if error
	b	encoding_completed
################################################################################################################################################
RECREATE_TREE_FROM_FILE:

		PRINT_STRING_LIT("Creating tree...\n")
	.data
	.align 2
raBuff:	.space 2048
	.text
	ori	$s0, $sp, 0
	subu	$sp, $sp, $t0
	ori	$s1, $sp, 0
	ori	$s2, $sp, 0						# $s2 - pointer to free place for node
								# $s4 - pointer to self
	
	ori	$t9, $s0, 0						# $t9 - pointer to free place for letter
	ori	$t8, $0, 32						# $t8 - length of a register
	xor	$t5, $t5, $t5					# $t5 - pointer to last visited element
								# $t4 - used for loading new B to $t2
	xor	$t3, $t3, $t3					# $t3 - number bits in $t2
	xor	$t2, $t2, $t2					# $t2 - bits from file header
	ori	$t1, $0, 1
	sll	$t1, $t1, 31					# $t1 - highest bit set - mask for bit
	xor	$t0, $t0, $t0					# $t0 - pointer to $ra in raBuff
	
	sw	$ra, raBuff($t0)
	addiu	$t0, $t0, 4
	
	addiu	$s4, $sp, -12
	jal	RECREATE_TREE
	ori	$s2, $t5, 0
	b	END_OF_RECREATION
RECREATE_TREE:
	bgeu	$t3, 9, ISENOUGH
ISNOTENOUGH_AFTER_ADD_8:
		READ_FROM_FILE($s7, inputbuff, 1, endExpl_3, endExpl_3)		# READ_ONE_BYTE
	lbu	$t4, inputbuff
	sb	$0, inputbuff
	
	sll	$t2, $t2, 8
	addiu	$t3, $t3, 8
	or	$t2, $t2, $t4
	bleu	$t3, 8, ISNOTENOUGH_AFTER_ADD_8
ISENOUGH:
	subu	$t7, $t8, $t3
	sllv	$t2, $t2, $t7
	and	$t6, $t2, $t1					# 0 or 1   -   0 - node, 1 - leaf
	srlv	$t2, $t2, $t7
	addiu	$t3, $t3, -1
	bnez	$t6, INSERTLEAF
ITSNOTLEAF:	
	sw	$ra, raBuff($t0)
	addiu	$t0, $t0, 4						# like frame pointer, but we keep only $ra and $s4
	sw	$s4, raBuff($t0)
	addiu	$t0, $t0, 4
	
	addiu	$sp, $sp, -12
	ori	$s4, $sp, 0					# $s4 - pointer to self
	ori	$s2, $sp, 0
	
	jal	RECREATE_TREE
	sw	$t5, 0($s4)
	jal	RECREATE_TREE
	sw	$t5, 4($s4)
	
	ori	$t5, $s4, 0
	addiu	$t0, $t0, -4
	lw	$s4, raBuff($t0)
	addiu	$t0, $t0, -4
	lw	$ra, raBuff($t0)
	jr	$ra
INSERTLEAF:
	addiu	$t3, $t3, -8
	srlv	$t4, $t2, $t3
	sb	$t4, -1($t9)
	addiu	$t9, $t9, -8
	ori	$t5, $t9, 0
	jr	$ra
END_OF_RECREATION:
	addiu	$t0, $t0, -4
	lw	$ra, raBuff($t0)
	jr	$ra
################################################################################################################################################
DECODE_AND_WRITE_TO_FILE:
	xor	$t4, $t4, $t4					# $t4 - number of B in outputbuff
	xor	$t3, $t3, $t3					# $t3 - number of bites currently written (and not readded ;D) in $t2
	xor	$t2, $t2, $t2					# $t2 - register <-> buffer
	xor	$t1, $t1, $t1
	addiu	$t1, $t1, -1
	sll	$t1, $t1, 31					# $t1 - bit mask (higherst bit set)
	ori	$t0, $0, 32						# $t0 - length of a register
INTERNAL.SUPER.LOOP.FOR.EDGE.CASES_DECODE:
	ori	$s4, $v0, 0					# $s4 - detects end of buffer
	xor	$t9, $t9, $t9					# $t9 - input iterator
####################################
LOOPDECODEFILE:
	lbu	$t8, inputbuff($t9)
	addiu	$t9, $t9, 1
	bgtu	$t9, $s4, PROCEDURE_FOR_EDGE_CASES_DEC			# rest from this buffer	
	sll	$t2, $t2, 8						# prepare place for new B
	or	$t2, $t2, $t8					# next B in register at lowest bites
	addiu	$t3, $t3, 8
	bleu	$t3, 10, LOOPDECODEFILE
	
NEXTLETTERDECODER:
	sub	$t8, $t0, $t3					# how much to shift left to get higherst bit
	sllv	$t8, $t2, $t8	
	and	$t5, $t8, $t1					# $t5 - highest bit value
	addiu	$t3, $t3, -1
	bnez	$t5, PLAIN_ASCII_READ					# $t5 == 1 its bare char time
	
	ori	$t5, $s2, 0						# pointer to root
	beq	$t5, $s1, ONE_LETTER_IN_CODE				# when input file had only one letter
	xor	$t7, $t7, $t7					# counter for 1's
	
LOOP_DECODE_CHAR:
	sll	$t8, $t8, 1
	and	$t6, $t8, $t1
	addiu	$t3, $t3, -1
	srl	$t6, $t6, 29					# $t6 - 0 or 4
	addu	$t7, $t7, $t6					# used to check if code contains only zeroes
	addu	$t5, $t5, $t6					# $t5 - pointer to left or right depending on $t6
	lw	$t5, 0($t5)						# $t5 - pointer to correct element
	bltu	$t5, $s1, LOOP_DECODE_CHAR
	bnez	$t7, NORMALCODE					# probably endinig code or letter ended artificialy with 1
ONE_LETTER_IN_CODE:							# one letter, or 000000001 or 000000000
	sll	$t8, $t8, 1
	and	$t6, $t8, $t1					# extracting next bit
	addiu	$t3, $t3, -1
	beqz	$t6, ACTUALLYWRITE_DECODE				# code that ends file ((00000000) + (0))
NORMALCODE:
	lbu	$t5, 7($t5)
	sb	$t5, outputbuff($t4)
	addiu	$t4, $t4, 1
	bgeu	$t4, memorySize, WRITE_TO_OUTPUT_DECODED
	bgtu	$t3, 10, NEXTLETTERDECODER
	b	LOOPDECODEFILE

WRITE_TO_OUTPUT_DECODED:
	ori	$v0, $0, 15
	ori	$a0, $s6, 0
	la	$a1, outputbuff
	ori	$a2, $t4, 0
	syscall							# ten syscall NIE ZMIENIA zawartosci rejestrow $t0-9
	blt	$v0, 0, endExpl_3					# if error
	xor	$t4, $t4, $t4
	bgtu	$t3, 10, NEXTLETTERDECODER
	b	LOOPDECODEFILE
	
PLAIN_ASCII_READ:							# 1 + bare ascii code
	addiu	$t3, $t3, -8
	srlv	$t8, $t2, $t3		
	sb	$t8, outputbuff($t4)	
	addiu	$t4, $t4, 1
	bgeu	$t4, memorySize, WRITE_TO_OUTPUT_DECODED
	bgtu	$t3, 10, NEXTLETTERDECODER
	b	LOOPDECODEFILE					# if $t3 (number of inserted) > 16, write b to buffer

PROCEDURE_FOR_EDGE_CASES_DEC:						# it could be end of input file (it shouldn't be when decoding)
								# but it as well might be only end
								# of first input segment
		READ_FROM_FILE($s7, inputbuff, memorySize, ACTUALLYWRITE_DECODE, endExpl_3)
	b	INTERNAL.SUPER.LOOP.FOR.EDGE.CASES_DECODE
ACTUALLYWRITE_DECODE:
	ori	$v0, $0, 15
	ori	$a0, $s6, 0
	la	$a1, outputbuff
	ori	$a2, $t4, 0
	syscall							# ten syscall NIE ZMIENIA zawartosci rejestrow $t0-9
	blt	$v0, 0, endExpl_3					# if error
	b	decoding_completed
################################################################################################################################################
