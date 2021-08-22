global callMe
section .text

callMe:
; RDI new block
; RSI old block
; RDX new data chunk size
; RCX block Align
; R8 m

    push rdx
    push rcx
    push rbx

    mov rax, rdx
    xor rdx, rdx
    div rcx

    xchg rcx, rax ; RCX numero de iteraciones y rax block Align

    mul r8 ; Block Align * m

copyData:
    xor rdx, rdx
L1:
    mov bl, [rsi + rdx]
    mov [rdi], bl
    inc rdi
    inc rdx
    cmp rdx, rax
    jl L1

    add rsi, rax

    loop copyData
    ret
