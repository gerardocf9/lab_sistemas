.586 
.MODEL flat, stdcall 
OPTION CASEMAP:NONE 
Include windows.inc 
Include kernel32.inc 
Include masm32.inc 
IncludeLib C:\masm32\kernel32.lib 
IncludeLib masm32.lib 
Main PROTO 
Print_Text Macro txt:REQ 
	Invoke StdOut,ADDR txt 
EndM 
Get_Input Macro prompt:REQ,buffer:REQ 
	Invoke StdOut,ADDR prompt 
	Invoke StdIn,ADDR buffer, LengthOf buffer 
EndM 
.DATA 
	Msg1 DB "Please Type Something: ",0AH,0DH,0 
	Msg2 DB "You Typed: ",0 
	Msg4 DB "Press Enter to Exit",0 
	CRLF DB 0AH,0DH,0 
.DATA? 
	inbuf DB 100 DUP (?) 
	textbuf2 DB 100 DUP (?) 
.CODE 
Start: 
	  Invoke Main 
	  Invoke ExitProcess,0 
Main Proc 
	XOR EAX,EAX 
	Get_Input Msg1, inbuf 
	Print_Text Msg2 
	Print_Text inbuf 
	Print_Text textbuf2 
	Print_Text CRLF 
	Get_Input Msg4,inbuf 
	RET 
Main EndP 
End Start 