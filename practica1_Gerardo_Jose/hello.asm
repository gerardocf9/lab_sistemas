;********************************************
; programa para la escritura de hello world
; comentarios agregados posteriormente
;********************************************

;directivas y especificaciones del tipo de memoria
.386
.model flat, stdcall
;para que no sea case sensitive
option casemap:none

;inclusión de las librerías necesarias para hacer llamadas
;al sistema. (cabe resaltar que todas están en la carpeta masm32)
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

;comienzo del segmento de data
.data
msg db "Hello world!!!", 0
cpt db "MY FIRST PROGRAM!!!", 0

;comienzo del segmento de codigo
.code
;inicio del programa
start:
;invoke hace un syscall y envía la dirección de las strings-data a imprimir
invoke MessageBox, NULL, addr msg, addr cpt, MB_OK + MB_ICONINFORMATION
;fin del programa, y llama al fin de la ejecución
invoke ExitProcess, NULL

end start
