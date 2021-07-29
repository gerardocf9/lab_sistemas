
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

coma db ",",0
Cant_lineas db 1

Aux_string db 512 dup(0) ;para el nuevo campo de la bbdd



new_file DB "BBDD.txt",0


.DATA? 
inbuf DB 100 DUP (?) 

hFile     	  dd ?
hFileWrite      dd ?
FileSize  	  dd ?
hMem         dd ?
BytesRead   dd ?

pos 		DB 10 dup(?)
ID   		DB 23 DUP (?) 
nam 	DB 80 DUP (?) 
N1  		DB  10 dup(?)
N2 		DB 10 dup(?)
N3  		DB 10 dup(?)

 bytewr    DD ?;variable adicional creada por necesidad para el proc
.CODE 
Start: 
    ;***************************************************
    ;handling the files

    ;******* file to read ************************
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

	;se escribe la fila
	invoke  StdOut,hMem
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	
	;********* file to write ************************
	
	invoke  CreateFile,offset new_file ,GENERIC_WRITE,0,0,\
	        CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0            
	mov     hFileWrite,eax
 	  ;invoke CreateFile,lpName,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL

	invoke WriteFile,hFileWrite,hMem,FileSize,ADDR bytewr,NULL
	;cantidad de bytes se consigue restando 2 direcciones de memoria xD

	


	;************************************************************************
	; lectura de valores	
	
	Get_Input MsgPos,  pos; pedir la posicion
	Get_Input MsgCed, ID; pedir la cedula
	Get_Input MsgNom, nam; pedir el nombre
	Get_Input MsgN1, N1; pedir la nota 1
	Get_Input MsgN2, N2; pedir la nota 2
	Get_Input MsgN3, N3; pedir la nota 3
	
	
	;*******************************************************
	; calculo de lineas

    ;USAMOS VARIOS REGISTROS PARA LLEVAR TODO A CABO 1 VEZ
    
    ;vemos que posicion del numero se quiere acceder
    ;mov efx, pos
    ;and efx, 30H


	mov ecx, 1 ;inicializamos el contador en 1 posible linea
	mov esi,  hMem ; vamos a trabajar con la fila, por eso usamos el handler de memoria...
	mov eax, 0 ; limpiamos eax, solo usaremos al (byte...) 
	cont_lineas:
		mov al, [esi] 
		
		cmp eax, 10 ;compara buscando caracter de salto de linea '\r' '\n' con \n = 10 decimal A hex, gracias olly
		jne n_linea_nueva
		inc ecx
		
		n_linea_nueva:
		
		cmp eax , 0 ; compara con el caracter de fin de archivo, end buffer...
	je  f_lineas
		
		inc esi
		
	jmp cont_lineas
	
	
	
	f_lineas:
	
	mov  edi, OFFSET Cant_lineas; guardamos la cantidad de lineas que hay! primero la memoria a un registro
	
	
	xor ecx, 30H; mascara para llevarlo a ascii
	mov [edi] , ecx ; luego el valor a la direccion
	
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	Print_Text Cant_lineas ;imprimimos
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	
	
	invoke lstrcat,offset Aux_string,OFFSET ID
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET nam
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N1
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N2
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N3
	invoke lstrcat,offset Aux_string,OFFSET CRLF
	
	;debug
	Print_Text pos
	Print_Text CRLF ;salto de linea
	
	Print_Text  Aux_string
	Print_Text CRLF ;salto de linea

	invoke WriteFile,hFileWrite,offset Aux_string,200,ADDR bytewr,NULL
	
	
	;*****************************************************
	; Fin Programa
	;se cierran los ficheros
	
	invoke  CloseHandle,hFile
	invoke  CloseHandle,hFileWrite
	
	
	
	;se libera la memoria dinamica
	invoke  GlobalFree,hMem
	;espera enter para salir y poder leer
	
	Print_Text CRLF ;salto de linea
	Get_Input Msg4,inbuf ;mensaje de salida
	
	
	;sale del programa
	Invoke ExitProcess,0 
	
	
End Start 
