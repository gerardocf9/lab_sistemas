.MODEL  small
.stack  100h

.data
Bufsize = 4096
input_file BYTE "input.txt",0
inHandle WORD ?
bytesRead WORD ?
buffer BYTE Bufsize DUP(?)

.code
main PROC
    mov ax,@data
    mov ds,ax

    ; Abrir el archivo
    mov ax,716ch                ; Funcion para crear o abrir un archivo
    mov bx,0                    ; Escogemos modo lectura
    mov cx,0                    ; Atributo normal
    mov dx,1                    ; Accion: abrir archivo
    mov si, OFFSET input_file   ; Pasamos el puntero al buffer
    int 21h                     ; llamamos a MS-DOS
    jc quit                     ; Salimos si ocurre un error
    mov inHandle, ax

    ; Leer el archivo
    mov ah, 3Fh                 ; Funcion para leer un archivo o un dispositivo
    mov bx, inHandle            ; Pasamos el "handle" del archivo
    mov cx, Bufsize             ; Numero maximo de bytes a leer
    mov dx, OFFSET buffer       ; Puntero al buffer
    int 21h                     ; Llamamos a MS-DOS
    jc quit                     ; Salimo si ocurre un error
    mov bytesRead, ax           ; Guardamos en bytesRead la cantidad bytes leidos

    ; Cerrar el Archivo
    mov ah,3Eh                  ; Funcion para cerrar un archivo
    mov bx, inHandle            ; Pasamos el handle del archivo que leimos
    int 21h                     ; Llamamos a MS-DOS
    jc quit                     ; quit if error

    ; Imprimir contendio en pantalla
    mov ah, 40h                 ; Funcion para escribir en un archivo o dispositivo
    mov bx, 1                   ; Handle de la salida estandar
    mov cx, bytesRead           ; Pasamos el numero de bytes a imprimir
    mov dx, OFFSET buffer       ; buffer pointer
    int 21h                     ; Llamamos a MS-DOS
    jc quit                     ; Salimos si ocurre un error

quit:
    .Exit
main ENDP
END main
