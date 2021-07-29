
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

; lectura de archivo
; calculos respectivos al archivo
; escritura de archivo stdout

; pedir informacion adicional
; re estructurar todo
; imprimir nuevo archivo

;escribir y guardar en el nuevo archivo


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

MsgPos DB "Please type the position where the new register will be inserted: ",0AH,0DH,0 

MsgNom DB "Please type the name: ",0AH,0DH,0 
MsgCed DB "Please type the ID: ",0AH,0DH,0 
MsgN1 DB "Please type first grade: ",0AH,0DH,0 
MsgN2 DB "Please type second grade: ",0AH,0DH,0
MsgN3 DB "Please type third grade: ",0AH,0DH,0


.DATA? 
inbuf DB 100 DUP (?) 

hFile     	  dd ?
FileSize  	  dd ?
hMem         dd ?
BytesRead   dd ?

pos 		dd 10 dup(?)
ID   		DB 23 DUP (?) 
nam 	DB 80 DUP (?) 
N1  		DB 10 dup(?)
N2 		DB 10 dup(?)
N3  		DB 10 dup(?)


.CODE 
Start: 

	Get_Input Msg1, inbuf 
	;se usa la api de windows para abrir la fila
	invoke  CreateFile,ADDR inbuf,GENERIC_READ,0,0,\
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
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	
	
	
	;************************************************************************
	; lectura de valores	
	
	Get_Input MsgPos,  pos; pedir la posicion
	Get_Input MsgCed, ID; pedir la cedula
	Get_Input MsgNom, nam; pedir el nombre
	Get_Input MsgN1, N1; pedir la nota 1
	Get_Input MsgN2, N2; pedir la nota 2
	Get_Input MsgN3, N3; pedir la nota 3
	
	
	invoke atodw, addr pos
	
	Print_Text pos
	Print_Text CRLF ;salto de linea
	
	Print_Text  ID
	Print_Text CRLF ;salto de linea
	
	Print_Text nam
	Print_Text CRLF ;salto de linea
	
	Print_Text N1
	Print_Text CRLF ;salto de linea
	
	Print_Text N2
	Print_Text CRLF ;salto de linea
	
	Print_Text N3
	Print_Text CRLF ;salto de linea
	
	
	
	;*****************************************************
	; Fin Programa

	
	;se libera la memoria dinamica
	invoke  GlobalFree,hMem
	;espera enter para salir y poder leer
	
	Print_Text CRLF ;salto de linea
	Get_Input Msg4,inbuf ;mensaje de salida
	
	
	;sale del programa
	Invoke ExitProcess,0 
	
	
End Start 
