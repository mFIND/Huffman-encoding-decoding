#include <stdio.h>
#include <stdint.h>

#define PROCESSING_MEMORY_SIZE 0x800

extern int mainAsm();

const int pathToFileSize = 0x80;
const int memorySize = PROCESSING_MEMORY_SIZE;		// last 2 Bytes in output require this

const int maxCodeLength = 0x8;

// almost 'just enought' to fit whole tree in worst scenario
unsigned char memBuff[5120];

unsigned char inputBuff[PROCESSING_MEMORY_SIZE + 2];
unsigned char outputBuff[PROCESSING_MEMORY_SIZE + 2];
unsigned char preheader[8];

unsigned char lettCounter[1024];



int main()
{
	int i;
	for(i = 0; i < memorySize || i < 5120; ++i){
		if(i < memorySize) 	inputBuff[i]	= (char)0;
		if(i < memorySize) 	outputBuff[i]	= (char)0;
		if(i < 5120)		memBuff[i]		= (char)0;
		if(i < 1024)		lettCounter[i]	= (char)0;
		if(i < 8)			preheader[i]	= (char)0;
	}
	
	printf("\n---> mainASM: %d\n",mainAsm());					// coule be void, doesn't matter
	
    return 0;
}
