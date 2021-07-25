.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
Include \masm32\include\masm32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
IncludeLib  \masm32\lib\masm32.lib

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
DlgProc PROTO :HWND, :DWORD, :DWORD, :DWORD


Get_Input Macro prompt:REQ,buffer:REQ
	Invoke StdOut,ADDR prompt
	Invoke StdIn,ADDR buffer, LengthOf buffer
EndM


.data
ClassName db "SimpleWinClass",0
AppName  db "Our Main Window",0
MenuName db "FirstMenu",0
DlgName db "MyDialog",0
TestString db "Hello, everybody",0
hwndDlg dd 0            ; Handle to the dialog box


.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?

inbuf DB 100 DUP (?)
hFile       dd ?
FileSize    dd ?
hMem        dd ?
BytesRead   dd ?

.const
IDM_EXIT equ 1
IDM_ABOUT equ 2
IDC_EDIT  equ 3000
IDC_BUTTON equ 3001
IDC_EXIT equ 3002

.code
start:
	invoke GetModuleHandle, NULL;necesario para manejar el modulo
	mov    hInstance,eax
	invoke GetCommandLine ;invocacion de terminal, no vienen por defecto
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT;llamada al proceso que lo hace todo
	invoke ExitProcess,eax

;proceso que lo hace todo...
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD;guardando valores iniciales, pasados en invoke
	;fijando variables locales
	LOCAL wc:WNDCLASSEX;creacion de una clase
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	;asignacion de los valores y direcciones a procedimientos necesarios en la clase
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc;procedimiento asociado a la clase que se encarga del manejo, win process
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,NULL
	push  hInst
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_WINDOW+1
	mov   wc.lpszMenuName,OFFSET MenuName
	mov   wc.lpszClassName,OFFSET ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION ;para el icono de la ventana
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW ;estilo del cursor
	mov   wc.hCursor,eax
	invoke RegisterClassEx, addr wc ;fijacion de registros-datos con la direccion-informacion de la clase wc (windows class)

	;utilizacion de la api de windows para crear, sin mostrar ni cargar una ventana, donde la info viene de la clase llenada arriba
	INVOKE CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           CW_USEDEFAULT,300,200,NULL,NULL,\
           hInst,NULL
	mov   hwnd,eax ;direccion de la ventana
	;api de windows para
	INVOKE ShowWindow, hwnd,SW_SHOWNORMAL ;mostrar la ventana
	INVOKE UpdateWindow, hwnd ;actualizar la ventana
	;ciclo "infinito" usado para mantener el programa corriendo y hacer una especie de framework manual, donde dependiendo de los
	;eventos que ocurran se toman distintas medidas
	.WHILE TRUE
                INVOKE GetMessage, ADDR msg,NULL,0,0 ;api de windows que permite "leer" mensajes-informacion de otras ventanas asociadas
                .BREAK .IF (!eax) ;sale si eax es null (0)
                .if hwndDlg!=0 ; si no se ha destruido la ventana
                        invoke IsDialogMessage,hwndDlg,ADDR msg
                        .if eax==TRUE
                                .continue
                        .endif
                .endif
                INVOKE TranslateMessage, ADDR msg
                INVOKE DispatchMessage, ADDR msg
	.ENDW ;fin del while
	mov     eax,msg.wParam
	ret
WinMain endp
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL;destruccion de la ventana
	.ELSEIF uMsg==WM_COMMAND
		mov eax,wParam
		.if ax==IDM_ABOUT
			invoke CreateDialogParam,hInstance, addr DlgName,hWnd,OFFSET DlgProc,NULL;llama al proceso de dialogo de ventana a traves de la api
			mov hwndDlg,eax
		.else
			invoke DestroyWindow, hWnd
		.endif
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.ENDIF
	xor    eax,eax
	ret
WndProc endp

DlgProc PROC hWnd:HWND,iMsg:DWORD,wParam:WPARAM, lParam:LPARAM
        .if iMsg==WM_INITDIALOG
		invoke GetDlgItem,hWnd,IDC_EDIT
		invoke SetFocus,eax
        .elseif iMsg==WM_CLOSE
		invoke EndDialog,hWnd,NULL
		mov hwndDlg,0 ;se cerro la ventana, translada la info al while de arriba
        .elseif iMsg==WM_COMMAND
		mov eax,wParam
		mov edx,eax
		shr edx,16
		.if dx==BN_CLICKED
			.if eax==IDC_EXIT
				invoke SendMessage,hWnd,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BUTTON

				invoke GetDlgItemText, hWnd,IDC_EDIT,addr inbuf,2000;lee el texto del input box, maximo de 2000 caracteres

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
				;se   cierra la fila
				invoke  CloseHandle,hFile
				;se escribe la fila
				invoke  StdOut,hMem
				;MessageBox
				invoke MessageBox, NULL, hMem, addr inbuf,
				MB_OK
				;se libera la memoria dinamica
				invoke  GlobalFree,hMem

				;invoke SetDlgItemText,hWnd,IDC_EDIT,ADDR TestString
			.endif
		.endif
        .else
		mov eax,FALSE
		ret
        .endif
        mov  eax,TRUE
        ret
DlgProc endp
end start
