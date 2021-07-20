.386 
.model flat, stdcall 
option casemap:none
 
include mensaje.inc 

.code 
start: 
	invoke MessageBox, NULL,addr MsgBoxText, addr MsgCaption, 
	MB_OK 
	invoke ExitProcess,NULL 
end start 