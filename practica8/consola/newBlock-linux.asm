global callMe
section .text

callMe:

    ;********************;
    ; RDI dest           ;
    ; RSI source         ;
    ; RDX newSize        ;
    ; RCX blockAlign     ;
    ; R8  m              ;
    ;********************;

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

    pop rbx

    ret
