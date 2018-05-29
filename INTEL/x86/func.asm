section .data

;	variables:

nOfBytes:			dd		0x00000000					; number of bytes read/written from/in _inputBuff

addrOfLett:			dd		0x00000000					; address of letters
addrOfNode:			dd		0x00000000					; address of node for child

nOfBitsCode:		db		0x01						; static; number of bits of code
bufferForCodes:		dd		0x00000000					; static; buffer for codes; 4B

nOfBitsHeader:		db		0x00						; static; number of bits of header
bufferForHeader:	dd		0x00000000					; static; buffer for header; 4B

;	functions:
extern	_maxCodeLength
extern	_enORdeCODE
extern	_errorWithFile
extern	_generalFailure
extern	_chooseInput
extern	_chooseOutput
extern	_terminatingAtUserRequest
extern	_printLetterStatistic

extern	_fread
extern	_fwrite
extern	_rewind

global	_mainAsm

;	arrays and other variables:
extern	_memBuff				; length of 5120
extern	_lettCounter
extern	_inputBuff
extern	_outputBuff
extern	_preheader

extern	_memorySize

section	.text

terminating:
	CALL	_terminatingAtUserRequest
	JMP		mainASMend

houstonWeveGotAProblem:
	CALL	_errorWithFile
	JMP		mainASMend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_mainAsm:
	PUSH	ebp
	MOV		ebp, esp
	
	CALL	_enORdeCODE
	CMP		eax, 2
	JGE		terminating
	PUSH	eax
	
	CALL	_chooseInput
	TEST	eax, -1
	JZ		houstonWeveGotAProblem
	PUSH	eax

	CALL	_chooseOutput
	TEST	eax, -1
	JZ		houstonWeveGotAProblem
	PUSH	eax
	
	TEST	DWORD [ebp-4], -1
	JNZ		toDecoding
	CALL	encoding
	TEST	eax, eax
	JNS		mainASMend
	CALL	_generalFailure
	JMP		mainASMend
	
toDecoding:
	CALL	decoding
	TEST	eax, eax
	JNS		mainASMend
	CALL	_generalFailure
	
mainASMend:
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
encoding:
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [ebp + 12]							; input FILE*
	
	PUSH	DWORD [ebp + 8]								; output FILE*
	
	PUSH	DWORD 0										; index of first element outside of nodes
	PUSH	DWORD 0										; index of first element outside of leaves
	
	PUSH	DWORD _memBuff
	
	PUSH	DWORD _lettCounter
	PUSH	DWORD _inputBuff
	PUSH	DWORD [_memorySize]
	PUSH	DWORD [ebp + 12]							; in FILE* input
	
	CALL	countLettersInInputFile						; (in FILE*, memory_size, _inputBuff, _lettCounter)
	 
	CALL	_rewind										; (in FILE*)
	ADD		esp, 12
	
	CALL	putLettersToMemBuff							; (_lettCounter, _memBuff)
	ADD		esp, 4
	MOV		[ebp-16], eax								; first index after letters in _memBuff !
	
	CALL	sortLetters									; (_memBuff, index)
	SHL		DWORD [ebp-16], 3							; address just after letters in _memBuff (offset from buffer beginning)
	
	CALL	createTree									; (_memBuff, index address outside of letters)
	
	TEST	eax, -1
	JZ		endEncoding									; internal program error
	MOV		DWORD [ebp-12], eax
	SUB		DWORD [ebp-16], 4
	ADD		esp, 4
	
	CALL	generateHeader								; (idx add. of outside let., idx add oo. node, outFILE*)
	ADD		esp, 8
	PUSH	eax
	
	CALL	readDataFromMem								; organises codes into different memory
	CALL	encodeFile									; (nOfBytes, output FILE*, input FILE*)
	
	;MOV		eax, DWORD [addrOfNode]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	;MOV		eax, DWORD [_memBuff + eax - 0]
	;MOV		eax, DWORD [_memBuff + eax - 0]
	;MOV		eax, DWORD [_memBuff + eax - 0]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	
	;MOV		eax, DWORD [_memBuff + eax - 8]
	;MOV		eax, DWORD [_memBuff + eax]
endEncoding:
	;XOR		eax, eax
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decoding:
	PUSH	ebp
	MOV		ebp, esp
	PUSH	DWORD 0
	PUSH	DWORD 0
														; [ebp + 12] - input FILE*
														; [ebp +  8] - output FILE*
	PUSH	DWORD [ebp + 12]
	CALL	fetchPreheader
	ADD		esp, 4
	CMP		eax, 8
	JNE		decodingError
	TEST	DWORD [_preheader + 0], -1
	JNZ		decodingError
	MOV		ebx, DWORD [_preheader + 4]
	
	SUB		ebx, 4
	MOV		DWORD [addrOfLett], ebx
	MOV		DWORD [ebp - 8], ebx
	ADD		ebx, 12
	MOV		DWORD [addrOfNode], ebx
	
	LEA		eax, [ebp - 4]
	PUSH	eax
	PUSH	DWORD [ebp + 12]
	CALL	recreateTreeFromFile						; (input FILE*, *numberOfCharactersRead)
	ADD		esp, 4
	
	MOV		ebx, DWORD [ebp - 8]
	MOV		DWORD [addrOfLett], ebx
	ADD		ebx, 12
	MOV		DWORD [addrOfNode], ebx
	MOV		DWORD [nOfBitsHeader], 0					; program uses bufferForHeader for decoding as well
	
	PUSH	DWORD [ebp +  8]							; output
	PUSH	DWORD [ebp + 12]							; input
	CALL	decodingFile								; (inFILE*, outFILE*, *numberOfChar.Read)
	
	TEST	eax, -1
	JZ		nothingLeftToDecode
	
	PUSH	DWORD [ebp + 8]
	PUSH	DWORD eax
	PUSH	DWORD 1
	PUSH	_outputBuff
	CALL	_fwrite
	
nothingLeftToDecode:
	;MOV		eax, DWORD [addrOfLett]
	
	;MOV		eax, DWORD [addrOfNode]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	;MOV		eax, DWORD [_memBuff + eax - 4]
	
	;MOV		al, BYTE [_memBuff + eax - 1]
	
decodingError:
	;XOR		eax, eax
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
countLettersInInputFile:								; counts letters in file
	PUSH	ebp
	MOV		ebp, esp
	PUSH	DWORD 0
	
loopForCountingInFile:
	PUSH	DWORD [ebp+8]								; FILE* input
	PUSH	DWORD [ebp+12]								; number of elements to read
	PUSH	DWORD 1										; size of an element
	PUSH	DWORD [ebp+16]								; inputBuff
	CALL	_fread
	ADD		esp, 16
														; eax - number of elements read
														; _fread doesn't clean up stack
	TEST	eax, eax
	JZ		endLetterCount
	
	MOV		[ebp-4], eax
	MOV		ecx, [ebp+16]								; _inputBuff
	MOV		ebx, [ebp+20]								; _lettCounter
	XOR		edx, edx
countLettersInBuff:
	XOR		eax, eax
	
	MOV		al, BYTE [ecx + edx]
	INC		edx
	
	SHL		ax, 2
	INC		DWORD [ebx + eax]

	CMP		edx, [ebp-4]
	JL		countLettersInBuff
	JMP		loopForCountingInFile
endLetterCount:
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putLettersToMemBuff:									; inserts letters to buffer
	PUSH	ebp
	MOV		ebp, esp
	
	XOR		eax, eax
	INC		eax
	SHL		eax, 10
	MOV		ebx, [ebp+8]								; pointer to lettCounter
	MOV		ecx, [ebp+12]								; pointer to end of memBuff
lettersToBuffLoop:
	SUB		eax, 4
	MOV		edx, [ebx + eax]
	TEST	edx, edx
	JZ		notToInsert
	
	MOV		[ecx+4], edx
	MOV		edx, eax
	SHR		edx, 2
	MOV		[ecx+3], dl
	ADD		ecx, 8
notToInsert:
	TEST	eax, eax
	JNZ		lettersToBuffLoop

	SUB		ecx, [ebp+12]
	SHR		ecx, 3
	MOV		eax, ecx
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sortLetters:											; insertion sort (max 256 elements to sort in this program)
	PUSH	ebp
	MOV		ebp, esp

	MOV		esi, [ebp+8]								; pointer to table _memBuff
	XOR		edx, edx									; where to sort to 
outerLoop:
	MOV		eax, [ebp+12]
	MOV		edi, eax									; index of greatest element (points outside of leaves at the beginning)
innerLoop:
	DEC		eax											; current table index
	
	CMP		eax, edx
	JL		swapElements
	
	MOV		ebx, [esi + eax*8 + 4]
	CMP		ebx, [esi + edi*8 + 4]
	CMOVG	edi, eax
	JMP		innerLoop
	
swapElements:											; swaps elements QWORD _memBuff[edi] and QWORD _memBuff[edx]
	CMP		edi, edx
	JE		swapped
	
	MOV		ecx, [esi + edi*8 + 0]
	XOR		[esi + edx*8 + 0], ecx
	XOR		ecx, [esi + edx*8 + 0]
	XOR		[esi + edx*8 + 0], ecx
	MOV		[esi + edi*8 + 0], ecx
	
	MOV		ecx, [esi + edi*8 + 4]
	XOR		[esi + edx*8 + 4], ecx
	XOR		ecx, [esi + edx*8 + 4]
	XOR		[esi + edx*8 + 4], ecx
	MOV		[esi + edi*8 + 4], ecx
swapped:
	INC		edx
	CMP		edx, [ebp+12]
	JNE		outerLoop
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
createTree:												; creates tree nodes and connections
	PUSH	ebp
	MOV		ebp, esp
														; (_memBuff, index address outside of letters)
	MOV		eax, [ebp+12]								; address of smallest leaf (offset in table)
	MOV		esi, [ebp+8]								; _memBuff
	
	SUB		eax, 4										; address of smallest leaf (offset in table)
	MOV		edi, eax									; address of last added node (offset in table)
	MOV		ebx, eax
	ADD		ebx, 12										; address of smallest node (offset in table)
	
getFirstSmallest:
	TEST	eax, eax
	JS		firstIsNode									; jump signed ( <0 )
	
	MOV		ecx, [esi + ebx - 8]
	TEST	ecx, ecx
	JZ		firstIsLetter
	CMP		ecx, [esi + eax]
	JGE		firstIsLetter
firstIsNode:
	TEST	DWORD [esi + ebx - 8], -1
	JZ		superERROR
	MOV		ecx, ebx
	ADD		ebx, 12
	JMP		firstDone
firstIsLetter:
	MOV		ecx, eax
	SUB		eax, 8
firstDone:
	
	TEST	eax, eax
	JS		secondIsNode
	
	MOV		edx, [esi + ebx - 8]
	TEST	edx, edx
	JZ		secondIsLetter
	CMP		edx, [esi + eax]
	JGE		secondIsLetter
secondIsNode:
	TEST	DWORD [esi + ebx - 8], -1
	JZ		treeCreated
	MOV		edx, ebx
	ADD		ebx, 12
	JMP		secondDone
secondIsLetter:
	MOV		edx, eax
	SUB		eax, 8
secondDone:
	ADD		edi, 12
	MOV		[esi + edi - 4], edx						; was '- 0'
	MOV		[esi + edi - 0], ecx						; was '- 4'
														; [ebp + 12] = addrOfLett
	PUSH	eax
	PUSH	ebx
	
	LEA		eax, [esi + ecx - 8]						; isLetter -> pipeline optimalization
	LEA		ebx, [esi + ecx]							; isNode
	CMP		ecx, DWORD [ebp + 12]
	CMOVG	ebx, eax
	MOV		ecx, [ebx]

	LEA		eax, [esi + edx - 8]						; isNode
	LEA		ebx, [esi + edx]							; isLetter -> pipeline optimalization
	CMP		edx, DWORD [ebp + 12]
	CMOVG	ebx, eax
	MOV		edx, [ebx]
	
	POP		ebx
	POP		eax	
	
	ADD		ecx, edx
	MOV		[esi + edi - 8], ecx

	JMP		getFirstSmallest
	
superERROR:
	XOR		eax, eax
	JMP		superERRORInfo								; should never happen
treeCreated:
	MOV		eax, edi
superERRORInfo:
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
generateHeader:											; creates codes and file header
	PUSH	ebp
	MOV		ebp, esp
														; (address of letters, \
														address node, outputFILE*)
	PUSH	DWORD [ebp + 16]
	PUSH	DWORD [ebp +  8]
	CALL	writePreheader								; (address of letters, output FILE*)
	ADD		esp, 4
	
	MOV		eax, DWORD [ebp + 8]
	MOV		DWORD [addrOfLett], eax
	MOV		eax, DWORD [ebp + 12]
	MOV		DWORD [addrOfNode], eax
	
	CALL	generateCodesAndFileHeader					; (outFILE*)
	CALL	saveIfMoreEqualEight
	
	MOV		eax, DWORD [nOfBytes]
	
	TEST	BYTE [nOfBitsHeader], -1
	JZ		treeHeaderInBuffer
	
	MOV		edx, 8
	SUB		dl, BYTE [nOfBitsHeader]
	
	SHLX	edx, DWORD [bufferForHeader], edx
	MOV		BYTE [_outputBuff + eax], dl
	INC		DWORD [nOfBytes]
	INC		eax
	
	CMP		eax, DWORD [_memorySize]
	JL		treeHeaderInBuffer
	
	PUSH	DWORD [ebp + 16]
	PUSH	DWORD [nOfBytes]
	PUSH	DWORD 1
	PUSH	DWORD _outputBuff
	CALL	_fwrite
	
	XOR		eax, eax
treeHeaderInBuffer:
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
writePreheader:											; creates info about file as a whole and magic number
	PUSH	ebp
	MOV		ebp, esp
	
	MOV		DWORD[_preheader + 0], 0					; magic number
	MOV		eax, [ebp+8]
	ADD		eax, 4
	MOV		DWORD[_preheader + 4], eax					; number of B needed for leaves
	
	PUSH	DWORD [ebp + 12]
	PUSH	DWORD 8
	PUSH	DWORD 1
	PUSH	_preheader
	CALL	_fwrite
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
generateCodesAndFileHeader:								; saves tree structure to header and generates codes for letters
	PUSH	ebp
	MOV		ebp, esp
														; ()
	PUSH	DWORD [ebp + 8]
	CALL	saveIfMoreEqualEight
	ADD		esp, 4
	
	MOV		eax, DWORD [addrOfNode]
	CMP		eax, DWORD [addrOfLett]	
	JLE		isLetter
	
	INC		BYTE [nOfBitsHeader]
	INC		BYTE [nOfBitsCode]
	SHL		DWORD [bufferForHeader], 1
	SHL		DWORD [bufferForCodes], 1
	
	PUSH	DWORD [addrOfNode]
	PUSH	DWORD [bufferForCodes]
	PUSH	DWORD [ebp + 8]
	
	MOV		eax, DWORD [ebp - 4]
	MOV		eax, DWORD [_memBuff + eax - 0]
	MOV		DWORD [addrOfNode], eax
	
	CALL	generateCodesAndFileHeader
	
	MOV		eax, DWORD [ebp - 4]
	MOV		eax, DWORD [_memBuff + eax - 4]
	MOV		DWORD [addrOfNode], eax
	
	XOR		eax, eax
	MOV		eax, DWORD [ebp - 8]		; ?
	OR		eax, 1
	MOV		DWORD [bufferForCodes], eax
	
	CALL	generateCodesAndFileHeader
	
	DEC		BYTE [nOfBitsCode]
	
	MOV		eax, DWORD [ebp - 4]
	MOV		DWORD [addrOfNode], eax
	
exitForLettersFromGenerationEncoding:	
	MOV		esp, ebp
	POP		ebp
	RET
;	;	;	;	;	;	;	;	;	;	;	;
isLetter:
	ADD		BYTE [nOfBitsHeader], 9						; place for header
	SHL		DWORD [bufferForHeader], 9
	OR		DWORD [bufferForHeader], 0x100
	XOR		ebx, ebx
	MOV		bl, BYTE [_memBuff + eax - 1]
	OR		DWORD [bufferForHeader], ebx				; header contains next 9 bits	
	XOR		ebx, ebx
	CMP		BYTE [nOfBitsCode], 8						; maxCodeLen
	JG		barecode
	CMP		DWORD [bufferForCodes], 0
	JZ		codeWith_1
	
	MOV		bl, BYTE [nOfBitsCode]
	MOV		BYTE [_memBuff + eax - 2], bl
	MOV		ebx, DWORD [bufferForCodes]
	MOV		WORD [_memBuff + eax - 4], bx

	JMP		exitForLettersFromGenerationEncoding
codeWith_1:
	MOV		bl, BYTE [nOfBitsCode]
	INC		bl
	MOV		BYTE [_memBuff + eax - 2], bl
	
	MOV		ebx, DWORD [bufferForCodes]
	SHL		bx, 1
	OR		bx, 1
	MOV		WORD [_memBuff + eax - 4], bx
	JMP		exitForLettersFromGenerationEncoding
barecode:
	MOV		BYTE [_memBuff + eax - 2], -1
	JMP		exitForLettersFromGenerationEncoding
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
saveIfMoreEqualEight:
	CMP		BYTE [nOfBitsHeader], 8
	JL		endOfSaving
	
	PUSH	ebp
	MOV		ebp, esp
beginningOfSaving:
	SUB		BYTE [nOfBitsHeader], 8

	XOR		eax, eax
	MOV		al, BYTE [nOfBitsHeader]
	
	SHRX	ebx, DWORD [bufferForHeader], eax			; http://www.felixcloutier.com/x86/SARX:SHLX:SHRX.html
	
	MOV		ecx, DWORD [nOfBytes]
	MOV		BYTE [_outputBuff + ecx], bl
	INC		DWORD [nOfBytes]
	INC		ecx
	
	CMP		ecx, [_memorySize]
	JL		noFread
	
	PUSH	DWORD [ebp + 8]
	PUSH	DWORD [nOfBytes]
	PUSH	DWORD 1
	PUSH	DWORD _outputBuff
	CALL	_fwrite
	
	MOV		DWORD [nOfBytes], 0
noFread:
	CMP		BYTE [nOfBitsHeader], 8
	JGE		beginningOfSaving
	
	MOV		esp, ebp
	POP		ebp
endOfSaving:
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readDataFromMem:										; moves data from memory to buffor to be accessible faster
	PUSH	ebp
	MOV		ebp, esp
	PUSH	DWORD [addrOfLett]
loopForReading:
	MOV		eax, DWORD [ebp - 4]
	
	XOR		ebx, ebx
	XOR		edx, edx
	XOR		ecx, ecx
	
	MOV		bl, BYTE [_memBuff + eax - 2]				; code length
	PUSH	ebx
	MOV		dx, WORD [_memBuff + eax - 4]				; code
	PUSH	edx
	MOV		cl, BYTE [_memBuff + eax - 1]				; char
	PUSH	ecx
	
	MOV		BYTE [_lettCounter + ecx*4 + 0], bl
	MOV		BYTE [_lettCounter + ecx*4 + 1], 0
	MOV		WORD [_lettCounter + ecx*4 + 2], dx
	
	PUSH	DWORD [_memBuff + eax - 0]					; count
	
	CALL	_printLetterStatistic
	ADD		esp, 16
	
	SUB		DWORD [ebp - 4], 8
	JNS		loopForReading								; jump not sign
	
	MOV		eax, DWORD [ebp - 4]
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
encodeFile:
	PUSH	ebp
	MOV		ebp, esp
														; {output FILE*, input FILE*)
	PUSH	DWORD 9
	PUSH	DWORD 0x100
	
	MOV		edi, DWORD [ebp + 8]
	XOR		esi, esi
	XOR		edx, edx
	XOR		ecx, ecx
	XOR		ebx, ebx
	XOR		eax, eax									; buffer input								- _inputBuff
getDataFromFile:										; buffer output								- _outputBuff
	PUSH	edi											; number of bytes in buffer output			- edi
	PUSH	ebx											; number of bytes read from input buffer	- esi
	PUSH	eax											; register that holds one letters (/w mdfc) - edx
	PUSH	DWORD [ebp + 16]							; number of bytes read by _fread			- ecx
	CALL	readNewBufferFromInput						; buffer output temp (4B)					- ebx
	POP		DWORD [ebp + 16]							; number of bits in output temp (4B)		- eax
	
	MOV		ecx, eax
	XOR		esi, esi
	POP		eax
	POP		ebx
	POP		edi
	
	TEST	ecx, ecx
	JZ		encodingComplete
codeLetter:
	XOR		edx, edx
	MOV		dl, BYTE [_inputBuff + esi]
	MOV		dl, BYTE [_lettCounter + edx*4 + 0]
	CMP		edx, 255									; if length is greater than  maxLen, its set to 255, code for magic bit is 9 bits long
	JNE		valueIsOK
	
	MOV		edx, 9
	SHLX	ebx, ebx, edx								; place for bits
	ADD		eax, edx									; number of bits increased
	XOR		edx, edx
	OR		ebx, 0x100
	MOV		dl, BYTE [_inputBuff + esi]
	OR		ebx, edx
	INC		esi
	JMP		checkAndSaveToOutput
valueIsOK:
	SHLX	ebx, ebx, edx
	ADD		eax, edx
	XOR		edx, edx
	MOV		dl, BYTE [_inputBuff + esi]					; char
	MOV		dx, WORD [_lettCounter + edx*4 + 2]			; get code if CMP NotEqual 255
	OR		ebx, edx									; code lands in ebx
	INC		esi
checkAndSaveToOutput:	
	CMP		eax, 8
	JL		noWriteToOutput
saveToOutput:
	SUB		eax, 8
	SHRX	edx, ebx, eax
	MOV		BYTE [_outputBuff + edi], dl
	INC		edi
	
	CMP		edi, DWORD [_memorySize]
	JL		probablyEnoughtSaving
	
	PUSH	esi
	PUSH	ecx
	PUSH	ebx
	PUSH	eax
	
	PUSH	DWORD [ebp + 12]
	PUSH	DWORD edi
	PUSH	DWORD 1
	PUSH	DWORD _outputBuff
	CALL	_fwrite
	ADD		esp, 16
	
	XOR		edi, edi
	POP		eax
	POP		ebx
	POP		ecx
	POP		esi
	
probablyEnoughtSaving:
	CMP		eax, 8
	JGE		saveToOutput
noWriteToOutput:
	CMP		esi, ecx
	JL		codeLetter
	JMP		getDataFromFile
	
encodingComplete:
	TEST	eax, eax
	JZ		noLastThinsToSaveToOutput
	MOV		edx, 8
	SUB		edx, eax
	SUB		eax, 8
	SHLX	edx, ebx, edx
	MOV		BYTE [_outputBuff + edi], dl
	INC		edi
	TEST	eax, eax
	JNS		encodingComplete							; jump not signed, very unlikely
noLastThinsToSaveToOutput:
	MOV		WORD [_outputBuff + edi], 0
	INC		edi
	INC		edi
	
	PUSH	DWORD [ebp + 12]
	PUSH	DWORD edi
	PUSH	DWORD 1
	PUSH	DWORD _outputBuff
	CALL	_fwrite

	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readNewBufferFromInput:
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [ebp + 8]
	PUSH	DWORD [_memorySize]
	PUSH	DWORD 1
	PUSH	DWORD _inputBuff
	CALL	_fread
														; eax contains n. of elements read
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fetchPreheader:
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [ebp + 8]
	PUSH	DWORD 8
	PUSH	DWORD 1
	PUSH	DWORD _preheader
	CALL	_fread
	
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
recreateTreeFromFile:
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [addrOfLett]							; address of myself / depending of if I am letter or node
	PUSH	DWORD [addrOfNode]							; address of myself / the correct one will be reduced / increased
	
	PUSH	DWORD [ebp + 12]							; *numberOfCharactersRead
	PUSH	DWORD [ebp + 8]								; inFILE*
	CALL	fetchNewIfLessThenNine
	; no ADD esp, 8										; because 'fetchNewIfLessThenNine' and 'recreateTreeFromFile'
														; uses the same input arguments
	XOR		eax, eax
	DEC		BYTE [nOfBitsHeader]
	MOV		al, BYTE [nOfBitsHeader]
	BT		DWORD [bufferForHeader], eax				; stores result in CF flag
	JC		isLeaf										; jump carry <- jump bit '1' (from BT) in this case
isNode:
	ADD		DWORD [addrOfNode], 12
	CALL	recreateTreeFromFile
	MOV		edi, DWORD [ebp - 8]
	MOV		DWORD [_memBuff + edi - 0], eax
	CALL	recreateTreeFromFile
	MOV		edi, DWORD [ebp - 8]
	MOV		DWORD [_memBuff + edi - 4], eax
	MOV		eax, edi
	JMP		returningFromTreeRecreating
isLeaf:
	SUB		DWORD [addrOfLett], 8
	SUB		BYTE [nOfBitsHeader], 8
	XOR		eax, eax
	MOV		al, [nOfBitsHeader]
	SHRX	eax, DWORD [bufferForHeader], eax
	
	MOV		ebx, DWORD [ebp - 4]
	MOV		BYTE [_memBuff + ebx - 1], al
	
	MOV		eax, ebx
returningFromTreeRecreating:
	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fetchNewIfLessThenNine:
	CMP		BYTE [nOfBitsHeader], 8
	JG		noNeedToFetch
	; if there are less than 9 bits
		; A: if there are bits in _inputBuff (if nOfBytes != 0 && nOfBytes != _memorySize)
			; read them
			; insert them into register
			; if at less than 9 bits
				; GOTO 'A'
		; else
			; read new bytes from inFILE
			; GOTO 'A'
	PUSH	ebp
	MOV		ebp, esp
	
;	TEST	DWORD [nOfBytes], -1
;	JZ		needToInputNewBuffer						; fires only first time in this function, probably should change that
repeatIfNecessary:
	MOV		ecx, DWORD [nOfBytes]
	MOV		ebx, DWORD [ebp + 12]
	CMP		ecx, [ebx]
	JE		needToInputNewBuffer
readyToRead:
	XOR		eax, eax
	MOV		al, BYTE [_inputBuff + ecx]
	INC		DWORD [nOfBytes]
	ADD		DWORD [nOfBitsHeader], 8
	SHL		DWORD [bufferForHeader], 8
	OR		DWORD [bufferForHeader], eax
	CMP		BYTE [nOfBitsHeader], 8
	JLE		repeatIfNecessary
	MOV		esp, ebp
	POP		ebp
noNeedToFetch:
	RET
needToInputNewBuffer:
	PUSH	DWORD [ebp + 8]
	CALL	readNewBufferFromInput
	MOV		DWORD [nOfBytes], 0
	MOV		ebx, DWORD [ebp + 12]
	MOV		[ebx], eax
	XOR		ecx, ecx
	JMP		readyToRead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decodingFile:											; (inFILE*, outFILE*, *numberOfChar.Read)
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [addrOfNode]
	PUSH	DWORD 0										; pointer to number of bytes written in outputBuff
	
	PUSH	DWORD [ebp + 16]
	PUSH	DWORD [ebp +  8]
nextLetter:
	CALL	fetchNewIfLessThenNine
	
	XOR		eax, eax
	DEC		BYTE [nOfBitsHeader]
	MOV		al, BYTE [nOfBitsHeader]
	
	BT		DWORD [bufferForHeader], eax				; stores result in CF flag
	JC		isBarecode									; jump carry <- jump bit '1' (from BT) in this case
	
	MOV		ebx, DWORD [ebp - 4]
	XOR		ecx, ecx
	XOR		edx, edx
	OR		edx, 1
	
normalCode:
	DEC		BYTE [nOfBitsHeader]
	DEC		eax
	BT		DWORD [bufferForHeader], eax
label_0:
	CMOVNC	ebx, [_memBuff + ebx - 0]
	CMOVC	ebx, [_memBuff + ebx - 4]					; CMOVC can access memory address even if CF=0, but _memBuff + ebx is safe to access
	CMOVC	ecx, edx									; to check if all bits were 0 or not (end detecting)
	
	CMP		ebx, [addrOfLett]
	JG		normalCode

probablyDecoded:
	TEST	ecx, -1
	JNZ		letterDecoded
	
	DEC		BYTE [nOfBitsHeader]
	DEC		eax
	BT		DWORD [bufferForHeader], eax
	JNC		decodingCompleted							; EOF
	
letterDecoded:
	MOV		al, BYTE [_memBuff + ebx - 1]
	LEA		ebx, [ebp - 8]								; we are doing this because we need this anyway 5 lines below
	MOV		ecx, [ebx]
	MOV		BYTE [_outputBuff + ecx], al
	INC		DWORD [ebx]
	
	PUSH	ebx
	PUSH	DWORD [ebp + 12]
	
	CALL	writeToOutputIfNecessery
	ADD		esp, 8
	
	JMP		nextLetter
isBarecode:
	SUB		BYTE [nOfBitsHeader], 8
	SUB		eax, 8										; eax contains value from before
	SHRX	eax, DWORD [bufferForHeader], eax
	
	LEA		ebx, [ebp - 8]
	MOV		ecx, [ebx]
	MOV		BYTE [_outputBuff + ecx], al
	INC		DWORD [ebx]
	
	PUSH	ebx
	PUSH	DWORD [ebp + 12]
	CALL	writeToOutputIfNecessery
	ADD		esp, 8
	
	JMP		nextLetter
decodingCompleted:
	MOV		eax, [ebp - 8]

	MOV		esp, ebp
	POP		ebp
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
writeToOutputIfNecessery:
	MOV		ebx, DWORD [esp + 8]
	MOV		ecx, [ebx]
	CMP		ecx, DWORD [_memorySize]
	JL		nothingToWrite
	
	PUSH	ebp
	MOV		ebp, esp
	
	PUSH	DWORD [ebp + 8]								; outFILE*
	PUSH	ecx
	PUSH	1
	PUSH	_outputBuff
	CALL	_fwrite
	
	MOV		ebx, DWORD [ebp + 12]
	MOV		DWORD [ebx], 0
	
	MOV		esp, ebp
	POP		ebp
nothingToWrite:
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
