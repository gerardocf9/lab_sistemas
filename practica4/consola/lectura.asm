
.586
.MODEL flat, stdcall
OPTION CASEMAP:NONE
Include windows.inc
Include kernel32.inc
Include masm32.inc
include  user32.inc

IncludeLib kernel32.lib
IncludeLib masm32.lib
includelib user32.lib




Main PROTO
	Print_Text Macro txt:REQ
	Invoke StdOut,ADDR txt
EndM
Get_Input Macro prompt:REQ,buffer:REQ
	Invoke StdOut,ADDR prompt
	Invoke StdIn,ADDR buffer, LengthOf buffer
EndM

.DATA
Msg1 DB "Please Type the file is name or path: ",0AH,0DH,0
Msg4 DB "Press Enter to Exit",0AH,0DH,0
CRLF DB 0AH,0DH,0


.DATA?
inbuf DB 100 DUP (?)


hFile       dd ?
FileSize    dd ?
hMem        dd ?
BytesRead   dd ?


.CODE
Start:

	 Get_Input Msg1, inbuf
	 ;se usa la api de windows para abrir la fila
	invoke  CreateFile,ADDR inbuf,GENERIC_READ,0,0,\
	            OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0

	mov     hFile,eax

	;obtencion del tamano de la fila para pedir memoria dinamica
	invoke  GetFileSize,eax,0

	mov     FileSize,eax
	inc     eax

	;pedir memoria dinamica
	invoke  GlobalAlloc,GMEM_FIXED,eax
	mov     hMem,eax

	add     eax,FileSize

	mov     BYTE PTR [eax],0   ; Set the last byte to NULL so that StdOut
	                   ; can safely display the text in memory.

	;finalmente se lee la fila
	invoke  ReadFile,hFile,hMem,FileSize,ADDR BytesRead,0

	;se   cierra la fila
	invoke  CloseHandle,hFile

	;se escribe la fila
	invoke  StdOut,hMem

	;se libera la memoria dinamica

	invoke  GlobalFree,hMem

	;espera enter para salir y poder leer
	Print_Text CRLF ;salto de linea
	Get_Input Msg4,inbuf ;mensaje de salida


     ;sale del programa
	 Invoke ExitProcess,0


End Start
