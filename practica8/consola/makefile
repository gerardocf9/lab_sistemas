all: test test-win

test: main.c newBlock-linux.o
	clang main.c newBlock-linux.o -o test

test-win: main.c newBlock-win.obj
	x86_64-w64-mingw32-gcc newBlock-win.obj main.c -o test-win

newBlock-linux.o: newBlock-linux.asm
	nasm -f elf64 newBlock-linux.asm

newBlock-win.obj: newBlock-win.asm
	nasm -f win64 newBlock-win.asm

clear:
	rm newBlock-linux.o test
