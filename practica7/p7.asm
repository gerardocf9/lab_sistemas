
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


coppystring PROTO:DWORD,:DWORD, :DWORD

StrToNumb PROTO :DWORD


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

Msgmfactor DB "Please type the m factor for the reduction ",0AH,0DH,0
Msgaux DB "should be almost 1 ",0
erros_selec DB "Error! Invalid option!",0AH,0DH,0

Aux_string db 100 dup(0) ;para el nuevo campo de la bbdd
new_file DB "out.wav",0



.DATA?
inbuf DB 100 DUP (?)
buffer_lineas DB 100 DUP (?)

hFile     	  dd ?
hFileWrite      dd ?
FileSize  	  dd ?
hMem         dd ?
BytesRead   dd ?

pos 		DB 10 dup(?)
mfactor     DD ?
data_size   DD ?
frame_size  DD ? ;cant bytes por muestra, cant de bytes a escribir por paso
new_data_size DD ?;el nuevo valor de la data y nuevo valor de subchunk2size data_size/m
chunksize   DD ? ;nuevo valor de Chunksize 36+new_data_size

;*********************
iteraciones DD ?;cant_iteraciones para alcanzar el tamaño necesario


bytewr    DD ?;variable adicional creada por necesidad para el proc
BufferSize DD ?
Buffer_div_size DD ?
hMem_div dd ?

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

    ;*************************************************
    ;          selecting m factor
    selection:
	Print_Text Msgmfactor
    Print_Text Msgaux 
    Get_Input CRLF,  pos; pedir la posicion
    ;se convierte la cadena a entero para hacer las posibles comparaciones    
	invoke StrToNumb, OFFSET pos
	
	cmp eax, 1
	jge compres_part
	
	Print_Text erros_selec
	jmp selection
	

	;********************************************
	; compresing_file
	
	
	compres_part:
	
    mov mfactor,eax;guardando el valor de m 
    

	;obteniendo el valor de BlockAlign, es decir el tamano de 1 frame o 
    ;Num_channels*Bits per sample
    mov ebx, hMem
    mov eax, 0
	mov al,[ebx+32]
	mov ah, [ebx+33]
	mov frame_size, eax
	 mov eax, 0
	mov eax,[ebx+40]
	;obtencion del tamano del archivo   

	mov data_size, eax ; Tamano en Bytes

    ;calculo del tamano del nuevo archivo
    ;new_data_size = data_size/mfactor
    xor edx, edx
    xor ebx, ebx
	mov eax, data_size 
	mov ebx, mfactor
	div ebx ; eax = new_data_size
    mov new_data_size,eax ; Longitud_Datos se actualiza con su valor real

    ;calculo de chunksize
    add eax,36 ;tamano informacion+encabezado
    mov chunksize,eax

    ;****************************************************
    ; Escritura del encabezado


    mov esi, hMem ;Direccion inicial de la memoria
    push esi; guardamos por los invoke
    invoke WriteFile,hFileWrite,esi,4,ADDR bytewr,NULL;escritura de Chunkid
    
    invoke WriteFile,hFileWrite,offset chunksize,4,ADDR bytewr,NULL;escritura de Chunkid

    pop esi;
    add esi, 8;los 4 nytes del id y los 4 del chunksize
	invoke WriteFile,hFileWrite,esi,32,ADDR bytewr,NULL;escritura de encabezado hasta
    ;linea 40, chunk2size
 
    invoke WriteFile,hFileWrite,offset new_data_size,4,ADDR bytewr,NULL;escritura de new_data_size


    ;*******************************************************************
    ;procedemos a escribir el archivo, de la forma f(mI)
    ;es decir f(0), f(m), f(2m), ... , f(nm)

    ;calculo de iteraciones necesarias
    ;iteraciones = new_data_size/frame_size
    xor edx, edx
    xor ebx, ebx
	mov eax, new_data_size 
	mov ebx, frame_size
	div ebx ; eax = cant_ciclos para obtener los datos, (n)
    dec ebx; el "array" iria desde 0 hasta ese elemento, se saltara en igual
    mov iteraciones,eax ;iteraciones necesarias 

   ;La idea es recorrer el archivo y escribir solo cuando sea requerido, es 
   ;decir, cada frame_size ocurre 1 m elemento
   ;si se recorre el archivo en tamanos de frame_size, solo hay que comparar con m
   ; y un contador, reutilizando codigo de la practica anterior...

    ; direccion_inicial = base + m*n*frame_Size, base = hmem+144, ingresada por teclado
    ;n = contador, va desde 0 hasta iteraciones 

    mov edi, iteraciones;cantidad maxima
    mov ecx,0 ;va a ser nuestro contador
    mov esi, hMem ;Direccion inicial de la memoria
    add esi, 44;primer elemento de data
    push esi; guardamos el valor de esi por el procedimiento que viene se hara pop
   
    mov ebx, frame_size
    mov eax,mfactor;guardando el valor de m 
    mul ebx ; edx eax = eax * ebx = M*frame = CSSTE, esto se multiplicara al contador
    mov ebx,eax; lo guardamos siempre en ebx

    ;escribir = direccion inical + contador + csste...
    ;escribir = esi+ ecx*ebx

ciclo:
    pop esi ;recuperamos la direccion base
    push esi
    mov eax,ecx
    mul ebx ; ebx*ecx = n * (m*frame_size)
    add esi, eax; esi tendria la direccion inicial+ el desplazamiento
    inc ecx ; aumentamos el contador, asi seria 0, m, 2m, ... , iteracionesm 
    push ecx
    push edi
    mov ecx, frame_size
    invoke WriteFile,hFileWrite,esi,ecx,ADDR bytewr,NULL;escritura el el archivo
    pop edi
    pop ecx
    cmp edi,ecx
    jg ciclo; iteraciones - contador, si iteraciones es mayor sigue





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

    Ret
coppystring endp



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
