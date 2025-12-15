; loader_fixed.asm
[org 0x7c00]
BITS 16

start:
    cli

    ; Установим безопасный стек (real mode)
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Установим DS так, чтобы обращения к меткам в этом секторе работали корректно.
    ; BIOS загружает сектор в физ. 0x7C00, поэтому DS=0x0000 и адреса будут 0x7C00+offset.
    mov ax, 0x0000
    mov ds, ax

    ; ES:BX = адрес куда грузим ядро (0x1000:0x0000 -> физ 0x10000)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx          ; BX = 0x0000

    ; --- читаем ядро (real mode) ---
    mov ah, 0x02        ; функция чтения секторов
    mov al, 10          ; <- ВАЖНО: читать 10 секторов (kernel.bin ~4868 байт)
    mov ch, 0
    mov cl, 2           ; сектор 2 (kernel начинается со второго сектора)
    mov dh, 0
    ; НЕ трогать DL — BIOS уже положил туда диск
    int 0x13
    jc disk_error

    ; --- подготовка к Protected Mode ---
    cli
    lgdt [gdt_descriptor]

    ; Включаем PE бит в CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; дальний прыжок (очищает prefetch) -> загрузка CS из GDT
    jmp 0x08:pm_start

; ---------------- 32-bit code ----------------
BITS 32
pm_start:
    ; устанавливаем сегменты данных на селектор 0x10
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; стек в protected mode
    mov esp, 0x90000

    ; прыжок на физ. 0x10000 (там ядро)
    jmp 0x08:0x10000

; ---------------- error handler ----------------
disk_error:
    mov si, error_msg
    mov ah, 0x0e
.print:
    lodsb
    or al, al
    jz .hang
    int 0x10
    jmp .print
.hang:
    cli
    hlt
    jmp .hang

error_msg db "Disk Read Error!",0

; ---------------- GDT ----------------
gdt_start:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55
