global callMe
section .text

callMe:

    ; El ABI de windows y linux cambia en esto, windows solo pasa 4 parametros
    ; por registro, el resto se pasa por el stack

    ; RDI dest -> RCX
    ; RSI source -> RDX
    ; RDX newSize -> r8
    ; RCX blockAlign -> r9
    ; R8  m -> Stack

    ;; WINDOWS

;   pop rax m deberia ser pasado por stack pero si se hace pop tira segfault

    push rdi
    mov rdi, rcx

    push rsi
    mov rsi, rdx

    mov rdx, r8
    mov rcx, r9
    mov r8, 2   ; Aqui deberia pasarse rax, pero si se coloca el valor antes
                ; de compilar funciona sin problemas.

    ;; WINDOWS

    mov r10, rcx

    mov rax, rdx
    xor rdx, rdx
    div rcx

    push rax

    mov rax, r8
    mul rcx

    pop rcx

    push rbx

copyData:
    xor rdx, rdx

L1:
    mov bl, [rsi + rdx]
    mov [rdi], bl
    inc rdi
    inc rdx
    cmp rdx, r10
    jb L1

    add rsi, rax

    loop copyData

    pop rbx ; tanto en linux como en windows rbx debe ser conservado

    ;; Windows

    pop rsi
    pop rdi

    ;; Windows

    ret
