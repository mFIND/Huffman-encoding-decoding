CC=gcc -std=c99
CXX=i686-w64-mingw32-g++ -std=c++11
CFLAGS=-m32

ASM=nasm
LINUX32_AFLAGS=-f elf32
WIN32_AFLAGS=-f win32 -o func.o
AFLAGS=$(LINUX32_AFLAGS)


#  -fno-PIC  -  for linux linker !!!


all:result

func_for_asm.o: func_for_asm.cpp
	$(CXX) $(CFLAGS) -c func_for_asm.cpp
func.o: func.asm
	$(ASM) $(AFLAGS) func.asm 

	
main.o: main.c
	$(CC) $(CFLAGS) -c main.c
result: main.o func.o func_for_asm.o
	$(CXX) $(CFLAGS) main.o func.o func_for_asm.o -o result
# windows cleaner
cleanW:						 
	erase *.o
	erase *.bin
	erase result.exe
clean:
	rm *.o
	rm *.bin
	rm result
	