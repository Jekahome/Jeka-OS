; Теперь у нас минимальный рабочий загрузчик, который собирается, MBR сигнатура стоит (0xAA55), и QEMU запускается без ошибок NASM/LD.
; 
; Сейчас он ещё не грузит ядро, а просто показывает сообщение через BIOS (или ничего, если сообщение убрали).
; 
; 1. Следующий шаг — добавим чтение ядра по одному сектору через Int 13h.
; 2. Убедимся, что QEMU загружает ядро корректно.
; 
; 3. После этого добавим Protected Mode и прыжок на 32-битное ядро.

[org 0x7C00]
BITS 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Вывод сообщения (проверка сборки)
    mov si, msg
.print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print

.done:
    cli
    hlt
    jmp .done

msg db "BOOTLOADER OK",0

; MBR сигнатура
dw 0xAA55
