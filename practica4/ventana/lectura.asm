.386 
.model flat, stdcall 
option casemap:none

include windows.inc 
include kernel32.inc 
include user32.inc 
Include masm32.inc 

includelib user32.lib 
includelib kernel32.lib 
IncludeLib masm32.lib 


Main PROTO 
	Print_Text Macro txt:REQ 
	Invoke StdOut,ADDR txt 
EndM 
Get_Input Macro prompt:REQ,buffer:REQ 
	Invoke StdOut,ADDR prompt 
	Invoke StdIn,ADDR buffer, LengthOf buffer 
EndM 


.data 
MsgCaption      db  "Ventana de mensaje",0 
MsgBoxText      db  "Este es un programa simple para Windows.",0 

Msg1 DB "Please Type the file is name or path: ",0AH,0DH,0 
Msg4 DB "Press Enter to Exit",0AH,0DH,0 
CRLF DB 0AH,0DH,0 

FileName    db 'test.txt',0     ; file to read

.DATA? 
inbuf DB 100 DUP (?) 


hFile       dd ?
FileSize    dd ?
hMem        dd ?
BytesRead   dd ?


.code 
start: 

;	Get_Input Msg1, inbuf 
	 ;se usa la api de windows para abrir la fila
	invoke  CreateFile,ADDR FileName,GENERIC_READ,0,0,\
	            OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0            

	mov     hFile,eax
	
	;obtencion del tamaño de la fila para pedir memoria dinamica
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
	
	
	;MessageBox
	invoke MessageBox, NULL, hMem, addr FileName, 
	MB_OK 

	
	;se libera la memoria dinamica
	invoke  GlobalFree,hMem
	

	invoke ExitProcess,NULL 
	
end start 
