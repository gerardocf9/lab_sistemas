
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

NumbToStr   PROTO :DWORD,:DWORD


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
CRLF DB 0DH,0AH,0

MsgPos DB "Please type the position where the new register will be inserted. ",0AH,0DH,0
Msgaux DB "should be almost 1 and less than: ",0

MsgNom DB "Please type the name: ",0AH,0DH,0
MsgCed DB "Please type the ID: ",0AH,0DH,0
MsgN1 DB "Please type first grade: ",0AH,0DH,0
MsgN2 DB "Please type second grade: ",0AH,0DH,0
MsgN3 DB "Please type third grade: ",0AH,0DH,0

coma db ",",0

Aux_string db 100 dup(0) ;para el nuevo campo de la bbdd

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

BufferSize DD ?
Buffer_div_size DD ?
hMem_div dd ?

Cant_lineas        db 11 dup(?)  ; variable para la conversion de cadenas, 11 elementos porque 10 cubren max int y 1 caracter de terminacion
hCant_lineas   	  dd ?
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

	;se escribe el fichero
	invoke  StdOut,hMem
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	invoke  CloseHandle,hFile


	;********* file to write ************************
	;ADDR inbuf
	invoke  CreateFile,ADDR new_file ,GENERIC_WRITE,0,0,\
	        CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	mov     hFileWrite,eax
 	  ;invoke CreateFile,lpName,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL


	;cantidad de bytes se consigue restando 2 direcciones de memoria xD


	;*******************************************************
	; calculo de lineas


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
	inc ecx ; cantidad de lineas +1
	push ecx ;guardamos el valor numerico

	;conversion a ascii
	invoke  NumbToStr, ecx, ADDR Cant_lineas

	push eax
	mov  esi, OFFSET hCant_lineas; guardamos la cantidad de lineas que hay! primero la memoria a un registro
	mov     [esi],eax   ; store the character in the buffer
	pop esi

	;mov edi,
	;************************************************************************
	; lectura de valores

	Invoke lstrlen, OFFSET pos  ; Guardamos la longitud del string en ECX
        mov ecx, eax
        dec ecx

	;  ****  verificacion de posicion ****

	Print_Text MsgPos
	Print_Text Msgaux
	invoke  StdOut,esi
	Get_Input CRLF,  pos; pedir la posicion

	mov edi, OFFSET pos

	xor ecx, ecx
	mov bl, [edi]

	.WHILE bl >= 30h && bl <= 39h
	inc ecx
	mov bl, [edi + ecx]
	.ENDW

	xor eax, eax

	convertir:

	mov bl, [edi]
	imul eax, 10
	sub bl, 30h
	movzx ebx, bl
	add eax, ebx
	inc edi

	loop convertir



	push eax; Guardando el valor en el que se desa ingresar para recuperarlo
	;mas tarde facilmente


	;*********** Pedir el resto de los datos *************

	Get_Input MsgCed, ID; pedir la cedula
	Get_Input MsgNom, nam; pedir el nombre
	Get_Input MsgN1, N1; pedir la nota 1
	Get_Input MsgN2, N2; pedir la nota 2
	Get_Input MsgN3, N3; pedir la nota 3


	;****************************************************
	;   Creacion de la estring
	;**************************************************

	invoke lstrcat,offset Aux_string,OFFSET ID
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET nam
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N1
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N2
	invoke lstrcat,offset Aux_string,OFFSET coma
	invoke lstrcat,offset Aux_string,OFFSET N3

	Invoke lstrlen, offset Aux_string
	mov BufferSize,eax


	;*****************************************************************
	; ***************  Escritura en el archivo ***********************

	pop eax ; recuperamos el valo de la linea donde vamos a insertar
	pop ecx ;recuperamos el valor de la cantidad de lineas que hay

	cmp eax,1
	je first_line
	cmp ecx, eax
	je last_line
	jmp in_line

	first_line:

		invoke WriteFile,hFileWrite,offset Aux_string,BufferSize,ADDR bytewr,NULL;escritura de la cadena
		Invoke WriteFile,hFileWrite,offset CRLF,2,ADDR bytewr,NULL;escritura del salto de linea
		invoke WriteFile,hFileWrite,hMem,FileSize,ADDR bytewr,NULL   ;escritura del archivo
		jmp fin;listo

	last_line:

		invoke WriteFile,hFileWrite,hMem,FileSize,ADDR bytewr,NULL;escritura del archivo
		Invoke WriteFile,hFileWrite,offset CRLF,2,ADDR bytewr,NULL;escritura del salto de linea
		invoke WriteFile,hFileWrite,offset Aux_string,BufferSize,ADDR bytewr,NULL ; escritura del nuevo registro
		jmp fin;listo


	in_line:
	;eax contiene el lugar en el que se va a guardar, usamos un respaldo en edi
	mov edi,eax

	mov ecx, 1 ;inicializamos el contador en 1 posible linea
	mov esi,  hMem ; vamos a trabajar con el archivo, por eso usamos el handler de memoria...
	mov eax, 0 ; limpiamos eax, solo usaremos al (byte...)
	cont_lineas2:
		mov al, [esi]

		cmp eax, 10 ;compara buscando caracter de salto de linea '\r' '\n' con \n = 10 decimal A hex
		jne n_linea_nueva2
		;Se llego al punto en el que se escribiria la nueva linea
		inc ecx
		cmp edi, ecx
		je escritura

		n_linea_nueva2:
		cmp eax , 0 ; compara con el caracter de fin de archivo, end buffer...
	je  f_lineas2

		inc esi
	jmp cont_lineas2

	f_lineas2:
		jmp fin

	escritura:
		; eax tiene un caracter
		;esi direccion del hmem+cant caracteres     sirve
		; edi tiene el numero de linea a donde va
		;ecx tiene el contador de cuantos lineas  van
		inc esi
		push esi ; guardamos la direccion de hmem+cant_caracteres

		mov ecx, hMem; direccion inicial del archivo
		sub esi, ecx ;en esi se tiene cuantos caracteres hay

		mov edi, offset Buffer_div_size
		mov [edi] , esi ; luego el valor a la direccion

		invoke WriteFile,hFileWrite,hMem,Buffer_div_size,ADDR bytewr,NULL;escritura del archivo   primera parte


		invoke WriteFile,hFileWrite,offset Aux_string,BufferSize,ADDR bytewr,NULL ; escritura del nuevo registro
		Invoke WriteFile,hFileWrite,offset CRLF,2,ADDR bytewr,NULL;escritura del salto de linea

		pop eax ; guardamos en eax la direccion de donde me quede en el archivo
		mov   hMem_div,eax
		mov  ecx, FileSize
		sub ecx, esi ; en ecx quedan cuantos caracteres faltan
		mov [edi] , ecx ; luego el valor a la direccion
		invoke WriteFile,hFileWrite,hMem_div,Buffer_div_size,ADDR bytewr,NULL;escritura del archivo


	fin:
	;*****************************************************
	; Fin Programa
	;se cierran los ficheros

	invoke  CloseHandle,hFileWrite



	;se libera la memoria dinamica
	invoke  GlobalFree,hMem
	;espera enter para salir y poder leer



	Print_Text CRLF ;salto de linea
	Get_Input Msg4,inbuf ;mensaje de salida


	;sale del programa
	Invoke ExitProcess,0


	NumbToStr PROC uses ebx x:DWORD,buffer:DWORD

	mov     ecx,buffer
	mov     eax,x
	mov     ebx,10
	add     ecx,ebx             ; ecx = buffer + max size of string
	mov     BYTE PTR [ecx],0   ; store the character in the buffer
	dec ecx
	ciclo:
		xor     edx,edx
		div     ebx
		add     edx,48              ; convert the digit to ASCII
		mov     BYTE PTR [ecx],dl   ; store the character in the buffer
		dec     ecx                 ; decrement ecx pointing the buffer
		test    eax,eax             ; check if the quotient is 0
	jnz     ciclo

	inc     ecx
	mov     eax,ecx             ; eax points the string in the buffer
	ret

NumbToStr ENDP


End Start
