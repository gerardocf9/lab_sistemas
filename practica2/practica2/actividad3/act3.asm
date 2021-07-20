.MODEL  small 
.stack  100h 
.data 
msg db "Hello, World!",13,10,"$" 
.code 
_start: 
mov ax,@data 
mov ds,ax 
mov dx,offset msg 
mov ah,9 
int 21h 
mov ax,0C07h 
int 21h 
mov ax, 4C00h 
int 21h 
end _start 