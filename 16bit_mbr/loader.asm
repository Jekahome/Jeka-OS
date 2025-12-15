; =================================================================
; ФАЙЛ: loader.asm (Загружает 16-битное ядро в 0x7E00)
; =================================================================
[org 0x7c00]
BITS 16

start:
    cli                      ; Выключить прерывания
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00           ; Стек в 0x7C00

    ; --- 1. Чтение ядра (2 сектора с адреса 0x7E00) ---
    mov ah, 0x02             ; Функция: Read Sectors From Drive
    mov al, 0x02             ; Количество секторов (2)
    mov ch, 0x00             ; Цилиндр 0
    mov cl, 0x02             ; Сектор 2 (Сектор 1 - это MBR)
    mov dh, 0x00             ; Головка 0
    mov dl, 0x00             ; Диск 0 (Floppy)
    mov bx, 0x7E0            ; Адрес для загрузки (0x07E0:0x000 = 0x7E00)
    mov es, bx
    mov bx, 0x0000
    int 0x13                 ; Выполнить чтение

    jc disk_error            ; Если ошибка, перейти к ошибке

    ; --- 2. Передача управления ядру ---
    jmp 0x0000:0x7E00        ; Переход к kernel_start

; --- Ошибка диска ---
disk_error:
    mov si, disk_error_msg
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    hlt

disk_error_msg db "Disk Read Error!", 0xD, 0xA, 0

; --- Заполнение MBR ---
times 510 - ($ - $$) db 0
dw 0xaa55