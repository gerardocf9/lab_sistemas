
.MODEL  small 
.stack  100h 

.data
	Text_Buffer      dw ? 
	filehandle       dw ?
	file_name        db "boolean.txt",13,10,"$" 
	
	msg db "Hello, World!",13,10,"$" 


.code 

ReadFile proc   
	
	mov ah, 3dh ;open the file  
	mov al, 0 ;open for reading  
	lea dx, file_name   
	int 21h
	mov [filehandle], ax   
	mov ah, 3fh   
	lea dx, Text_Buffer   
	mov cx, 100 ; Read 100 Byte 
	mov bx, [filehandle]   
	int 21h   
	mov bx, [filehandle]   
	mov ah, 3eh ;close file   
	int 21h  
	ret
	
ReadFile endp

START:
;cargar data segment
	mov ax, @data 
	mov ds,ax
;procedimiento de lectura
	call ReadFile
	
;cargar la informacion
	mov dx,offset Text_Buffer 
	mov ah,9 
	int 21h 
;mostrar por pantalla la informacion
	mov ax,0C07h 
	int 21h 

_end:
;terminar
	mov ax, 4C00h 
	int 21h 

END START


