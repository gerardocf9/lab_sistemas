all: test

test: main.c makeNewDataBlock.o
	clang main.c makeNewDataBlock.o -o test

makeNewDataBlock.o: makeNewDataBlock.asm
	nasm -f elf64 makeNewDataBlock.asm

clear:
	rm makeNewDataBlock.o test
