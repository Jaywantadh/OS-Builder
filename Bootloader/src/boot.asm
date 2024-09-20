[BITS 16]
[ORG 0x7c00]


start:
    cli ; Clear Interrrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti ; Enables interrupts
    mov si, msg

print:
    lodsb ;Loads bytes at ds:si to AL register and increments SI
    cmp al, 0
    je done
    mov ah, 0x0E
    int 0x10
    jmp print

done:
    cli
    hlt ; Stops further CPU executions

msg: db 'HELLO CPU!', 0

times 510 - ($ - $$) db 0

dw 0xAA55
