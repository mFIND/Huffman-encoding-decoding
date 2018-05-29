####################################
	.macro SWAP_REG(%reg_1, %reg_2)
	xor %reg_1, %reg_1, %reg_2
	xor %reg_2, %reg_2, %reg_1
	xor %reg_1, %reg_1, %reg_2
	.end_macro
####################################
	.macro END
	PRINT_STRING_LIT("\nBye bye!")
	ori $v0, $0, 10
	syscall
	.end_macro
####################################
	.macro PRINT_STRING (%adressofstr)
	ori $v0, $0, 4
	la $a0, %adressofstr
	syscall
	.end_macro
####################################
	.macro PRINT_STRING_LIT (%str)
	.data
STRPRINT:	.asciiz %str
	.text
	ori $v0, $0, 4
	la $a0, STRPRINT
	syscall
	.end_macro
#################################### not used? V
	.macro PRINT_CHAR (%register)
	ori $v0, $0, 11
	la $a0, %register
	syscall
	.end_macro
####################################
	.macro PRINT_INT (%int)
	ori $a0, %int, 0
	ori $v0, $0, 1
	syscall
	.end_macro
####################################
	.macro PRINT_INT_HEX (%int)
	ori $a0, %int, 0
	ori $v0, $0, 34
	syscall
	.end_macro
####################################
	.macro OPEN_FILE(%fileloc, %flag, %mode, %endExpl_3)
	ori	$v0, $0, 13						# open file, later: file descriptor (negative if error)
								# descriptor: 0,1,2 cin,cout,cerr
	la	$a0, %fileloc
	ori	$a1, $0, %flag					# flags : 0 - read only, 1 - write only with create, 9 - write only with create and	append (ignores mode)
	ori	$a2, $0, %mode					# mode - ignored
	syscall
	bltz	$v0, %endExpl_3
	.end_macro
####################################
	.macro CLOSE_FILE(%reg)
	ori	$v0, $0, 16
	ori	$a0, %reg, 0
	syscall
	.end_macro
####################################
