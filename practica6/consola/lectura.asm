
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

coppystring PROTO:DWORD,:DWORD, :DWORD

StrToNumb PROTO :DWORD

WritingLine PROTO :DWORD, :DWORD

WritingLineFile PROTO :DWORD, :DWORD, :DWORD,:DWORD

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
MsgPos2 DB "Please type the position of the register that will be deleted ",0AH,0DH,0
Msgaux DB "should be almost 1 and less than: ",0
MsgNom DB "Please type the name: ",0AH,0DH,0
MsgCed DB "Please type the ID: ",0AH,0DH,0
MsgN1 DB "Please type first grade: ",0AH,0DH,0
MsgN2 DB "Please type second grade: ",0AH,0DH,0
MsgN3 DB "Please type third grade: ",0AH,0DH,0
MsgSeleccion DB "Please type 1: to insert a new camp 2: to delete a existing line ",0AH,0DH,0
erros_selec DB "Error! Invalid option!",0AH,0DH,0

coma db ",",0
Aux_string db 100 dup(0) ;para el nuevo campo de la bbdd
new_file DB "BBDD.txt",0

par1 DB "( ",0
par2 DB " )  ",0


.DATA?
inbuf DB 100 DUP (?)
buffer_lineas DB 100 DUP (?)

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
hDir_inicial	  dd ?
.CODE
Start:
    ;***************************************************
    ;handling the files

    ;******* file to read ************************
	Get_Input Msg1, inbuf
	;se usa la api de windows para abrir la archivo
	invoke  CreateFile,ADDR inbuf,GENERIC_READ,0,0,\
	OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	mov     hFile,eax

	;obtencion del tamaño de la archivo para pedir memoria dinamica
	invoke  GetFileSize,eax,0
	mov     FileSize,eax
	inc     eax
	;pedir memoria dinamica
	invoke  GlobalAlloc,GMEM_FIXED,eax
	mov     hMem,eax
	add     eax,FileSize
	mov     BYTE PTR [eax],0   ; Set the last byte to NULL so that StdOut
	; can safely display the text in memory.
	;finalmente se lee la archivo
	invoke  ReadFile,hFile,hMem,FileSize,ADDR BytesRead,0

	invoke  CloseHandle,hFile


	;********* file to write ************************
	;ADDR inbuf
	invoke  CreateFile,ADDR new_file ,GENERIC_WRITE,0,0,\
	        CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	mov     hFileWrite,eax
 	  ;invoke CreateFile,lpName,GENERIC_WRITE,NULL,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL

    ;*************************************************
    ;          selecting what to do

	Print_Text MsgSeleccion
	Get_Input CRLF,  pos; pedir la posicion
    ;se convierte la cadena a entero para hacer las posibles comparaciones    
	invoke StrToNumb, OFFSET pos
	
	cmp eax, 1
	je insert_line_part
	cmp eax, 2
	je remove_line_part
	
	Print_Text erros_selec
	jp fin
	
	
	;********************************************
	; removing the line
	
	
	remove_line_part:
	
	;********************************************************
	;printing the new version 
	
	mov ecx, 1 ;inicializamos el contador en 1 posible linea
	mov ebx,offset hDir_inicial
	mov esi,  hMem ; vamos a trabajar con el archivo, por eso usamos el handler de memoria...
	mov [ebx], esi
	
	ciclo_muestreo:
		mov eax, 0 ; limpiamos eax, solo usaremos al (byte...)
		mov al, [esi]

		cmp eax, 10 ;compara buscando caracter de salto de linea '\r' '\n' con \n = 10 decimal A hex
		jne no_nueva_linea
		
		push eax ;guardamos el caracter que estaba 
		push ecx;guardamos la posicion del contador
		;Se llego al punto en el que se escribiria la nueva linea
		;escribimos (n) 
		invoke  NumbToStr, ecx, ADDR Cant_lineas
		push eax
;****************************************************
		;aqui esta el bug de que se ensucia el buffer...
		Invoke StdOut,ADDR par1
;*****************************************************
		pop eax
		Invoke StdOut, eax
		Invoke StdOut,ADDR par2
		
		push esi
		invoke WritingLine, hDir_inicial, esi;devuelve la direccion final
		pop esi
		;guarda la direccion final como nueva direccion inicial
		mov ebx,offset hDir_inicial
		mov [ebx], eax

		Print_Text CRLF ;salto de linea	
		;incrementamos, recuperamos el caracter  y continuamos	
		pop ecx;recuperamos el valor del contador
		inc ecx
		pop eax ;recuperamos el caracter, para seguir con el ciclo sin tener que modificar

		no_nueva_linea:
		cmp eax , 0 ; compara con el caracter de fin de archivo, end buffer...
	je  f_lineas2

		inc esi
	jmp ciclo_muestreo

	f_lineas2:
	
	;se debe repetir la impresion una vez mas porque la ultima linra no tiene \n, tiene 0
	push eax ;guardamos el caracter que estaba 
	push ecx;guardamos la posicion del contador
	;Se llego al punto en el que se escribiria la nueva linea
	;escribimos (n) 
	invoke  NumbToStr, ecx, ADDR Cant_lineas
	push eax
	Invoke StdOut,ADDR par1
	pop eax
	Invoke StdOut, eax
	Invoke StdOut,ADDR par2
	invoke WritingLine, hDir_inicial, esi;devuelve la direccion final
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	;incrementamos, recuperamos el caracter  y continuamos
	
	pop ecx;recuperamos el valor del contador
	pop eax ;recuperamos el caracter, para seguir con el ciclo sin tener que modificar
	
	

	mov  edi, OFFSET Cant_lineas; guardamos la cantidad de lineas que hay! primero la memoria a un registro
	push ecx ;guardamos el valor numerico

	;conversion a ascii
	invoke  NumbToStr, ecx, ADDR Cant_lineas

	push eax
	mov  esi, OFFSET hCant_lineas; guardamos la cantidad de lineas que hay! primero la memoria a un registro
	mov     [esi],eax   ; store the posicion in the buffer
	pop esi
;************************************************************************
	; lectura de valores
	Invoke lstrlen, OFFSET pos  ; Guardamos la longitud del string en ECX
        mov ecx, eax
        dec ecx
	;  ****  verificacion de posicion ****
	Print_Text MsgPos2
	Print_Text Msgaux
	invoke  StdOut,esi
	Get_Input CRLF,  pos; pedir la posicion

	invoke StrToNumb, OFFSET pos


	;push eax; Guardando el valor en el que se desa ingresar para recuperarlo
	;mas tarde facilmente

	
	;eax contiene el lugar en el que se va a guardar, usamos un respaldo en edi
	mov edi,eax
	mov ecx, 1 ;inicializamos el contador en 1 posible linea
	mov ebx,offset hDir_inicial
	mov esi,  hMem ; vamos a trabajar con el archivo, por eso usamos el handler de memoria...
	mov [ebx], esi
	
	ciclo_muestreo3:
		mov eax, 0 ; limpiamos eax, solo usaremos al (byte...)
		mov al, [esi]

		cmp eax, 10 ;compara buscando caracter de salto de linea '\r' '\n' con \n = 10 decimal A hex
		jne no_nueva_linea3
		
		push eax ;guardamos el caracter que estaba 
		push ecx;guardamos la posicion del contador
		;Se llego al punto en el que se escribiria la nueva linea
		;escribimos (n) 	
		push esi
		push edi
		invoke WritingLineFile, hDir_inicial, esi,ecx,edi;devuelve la direccion final
		pop edi
		pop esi
		;guarda la direccion final como nueva direccion inicial
		mov ebx,offset hDir_inicial
		mov [ebx], eax
		;incrementamos, recuperamos el caracter  y continuamos	
		pop ecx;recuperamos el valor del contador
		inc ecx
		pop eax ;recuperamos el caracter, para seguir con el ciclo sin tener que modificar

		no_nueva_linea3:
		cmp eax , 0 ; compara con el caracter de fin de archivo, end buffer...
	je  f_lineas3

		inc esi
	jmp ciclo_muestreo3

	f_lineas3:
	
	;se debe repetir la impresion una vez mas porque la ultima linra no tiene \n, tiene 0
	invoke WritingLineFile, hDir_inicial, esi,ecx,edi;devuelve la direccion final
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	;incrementamos, recuperamos el caracter  y continuamos
	
	
	
	
	; se termino la ejecucion de la opcion...
	jp fin

;******************************************************************
;         AGREGA UNA LINEA

insert_line_part:

	invoke  StdOut,hMem
	Print_Text CRLF ;salto de linea
	Print_Text CRLF ;salto de linea
	
	;*******************************************************
	; calculo de lineas


	mov ecx, 1 ;inicializamos el contador en 1 posible linea
	mov esi,  hMem ; vamos a trabajar con la archivo, por eso usamos el handler de memoria...
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
	mov     [esi],eax   ; store the posicion in the buffer
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

	invoke StrToNumb, OFFSET pos


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
	je  fin_de_linea

		inc esi
	jmp cont_lineas2

	fin_de_linea:
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
	
	
StrToNumb PROC uses edi ecx ebx position:DWORD	
	

	mov edi,  position

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
	
	Ret 

StrToNumb ENDP

coppystring proc uses esi edi  ecx ebx source:DWORD,dest:DWORD, tam:DWORD

	mov  esi,  source ;charging direction of source
	mov  edi,  dest ;chargin direction of destiny
	mov  ecx,  tam; charging numbers of bits to copy
	Lx:
		mov  al,[esi]          
		mov  [edi],al           
		inc  esi              
		inc  edi
	loop Lx
	inc edi
	mov eax,0h
	mov  [edi],eax   ; end string
	Ret
coppystring endp


WritingLine proc uses esi edi ecx ebx dir_inicial:DWORD, dir_final:DWORD


	; eax tiene un caracter
	;esi direccion del hmem+cant caracteres     sirve
	; edi tiene el numero de linea a donde va
	;ecx tiene el contador de cuantos lineas  van
	mov esi,dir_final
	;inc esi
	push esi ; guardamos la direccion de hmem+cant_caracteres

	mov ecx, dir_inicial; direccion inicial del archivo
	sub esi, ecx ;en esi se tiene cuantos caracteres hay

	;esi tiene cant bites a escribir
	;ecx tiene dir de donde se escribira
	
	invoke coppystring, dir_inicial, offset buffer_lineas, esi

	Print_Text buffer_lineas
	
	mov eax, dir_final
	inc eax ;incrementamos 1 para quitarnos el salto de linea

	Ret
WritingLine endp
WritingLineFile proc uses esi edi ecx ebx dir_inicial:DWORD, dir_final:DWORD, counter:DWORD, delete:DWORD


	; eax tiene un caracter
	;esi direccion del hmem+cant caracteres     sirve
	; edi tiene el numero de linea a donde va
	;ecx tiene el contador de cuantos lineas  van
	mov esi,dir_final
	;inc esi
	push esi ; guardamos la direccion de hmem+cant_caracteres

	mov ecx, dir_inicial; direccion inicial del archivo
	sub esi, ecx ;en esi se tiene cuantos caracteres hay

	;esi tiene cant bites a escribir
	;ecx tiene dir de donde se escribira
	mov eax, delete
	mov ecx, counter
	cmp eax,ecx
	je no_file
	invoke WriteFile,hFileWrite,dir_inicial,esi,ADDR bytewr,NULL;escritura del archivo
	no_file:
	mov eax, dir_final

	Ret
WritingLineFile endp
End Start
