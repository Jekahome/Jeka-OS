; =================================================================
; ФАЙЛ: kernel.asm (16-битное ядро)
; Загружается в 0x7E00 (следующий сектор)
; =================================================================
[org 0x7E00]
BITS 16

kernel_start:
    ; Очистка экрана через прямую запись в VGA (0xB8000)
    mov ax, 0xB800
    mov es, ax             ; ES:DI = 0xB800:0000 (видеопамять)
    mov di, 0x0
    
    mov cx, 2000           ; 80*25 = 2000 символов
    mov al, ' '            ; Символ пробела
    mov ah, 0x1F           ; Атрибут: Белый на Синем фоне (0x1F)
    
    mov word [es:di], ax   ; Запись слова (символ+атрибут)
    inc di
    inc di
    loop $ - 5             ; Заполнение 2000 символов

    ; Вывод 16-битной строки через BIOS INT 0x10
    mov si, message_16
    call print_string_16
    
    jmp $

; --- Подпрограмма вывода строки ---
print_string_16:
    mov ah, 0x0e            ; Функция 0x0E: Teletype Output (BIOS)
.loop:
    lodsb                   ; Загрузить байт из [si] в al
    cmp al, 0               ; Достигли ли конца строки?
    je .done                
    int 0x10                ; Вывод символа
    jmp .loop
.done:
    ret

message_16 db 'Kernel Loaded (16-bit Real Mode) successfully!', 0xD, 0xA, 0

times 512 * 2 - ($ - $$) db 0  ; Паддинг для ядра (2 сектора)