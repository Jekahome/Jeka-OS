; =================================================================
; ФАЙЛ: loader.asm (ИСПРАВЛЕННЫЙ)
; =================================================================
[org 0x7c00]
BITS 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; --- Чтение ядра ---
    mov bx, 0x1000          ; ES:BX = 0x10000
    mov es, bx              
    mov bx, 0x0             
    
    mov ah, 0x02            ; Чтение
    mov al, 1               ; 1 сектор
    mov ch, 0               ; Цилиндр 0
    mov cl, 2               ; Сектор 2 (Начало ядра)
    mov dh, 0               ; Головка 0
    mov dl, 0x00            ; Floppy
    
    int 0x13                
    jc disk_error           

    ; --- 5. ПЕРЕХОД В 32-БИТНЫЙ РЕЖИМ ---
    lgdt [gdt_descriptor]   

    mov eax, cr0            
    or eax, 0x1             ; Включаем бит PE (Protected Mode)
    mov cr0, eax            

    ; Дальний переход (использует селектор 0x08)
    jmp 0x08:pm_start

disk_error:
    mov si, msg_error
    call print_string
    jmp $

; -------------------------------------------
; GDT (Global Descriptor Table) - Без изменений
; -------------------------------------------
gdt_start:
    ; 0x00: Null Descriptor
    dd 0x0
    dd 0x0

    ; 0x08: Code Segment Descriptor
    dw 0xFFFF              
    dw 0x0                 
    db 0x0                 
    db 0x9A                ; Present, DPL=0, Executable, Readable
    db 0xCF                ; Flags (G=1, D=1/32bit) | Limit 16-19
    db 0x0                 

    ; 0x10: Data Segment Descriptor
    dw 0xFFFF              
    dw 0x0                 
    db 0x0                 
    db 0x92                ; Present, DPL=0, Data, Writable
    db 0xCF                ; Flags (G=1, D=1/32bit) | Limit 16-19
    db 0x0                 

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 
    dd gdt_start + 0x7C00       ; Абсолютный адрес GDT

; -------------------------------------------
; 32-БИТНЫЙ КОД
; -------------------------------------------
BITS 32
pm_start:
    jmp pm_mode_ready
    
pm_mode_ready:
    ; Инициализация всех сегментов (CS уже установлен 0x08)
    mov ax, 0x10             ; Селектор для сегмента данных
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ss, ax               
    mov esp, 0x90000         ; ИСПРАВЛЕНИЕ: Безопасный стек ниже 1MB

    ; Прыгаем в ядро (Дальний переход, чтобы гарантировать правильный CS)
    jmp 0x08:0x10000         ; ИСПРАВЛЕНИЕ: Far Jump в точку 0x10000

; -------------------------------------------
; Подпрограммы и данные (после GDT)
; -------------------------------------------
BITS 16
print_string:
    mov ah, 0x0E           
.loop:
    lodsb                  
    or al, al              
    jz .done               
    int 0x10               
    jmp .loop
.done:
    ret
    
msg_error db "DISK READ ERROR!", 0xA, 0xD, 0

; -------------------------------------------
; ЗАПОЛНЕНИЕ И СИГНАТУРА MBR
; -------------------------------------------
times 510 - ($ - $$) db 0
dw 0xaa55