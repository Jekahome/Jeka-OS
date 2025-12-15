; =================================================================
; ФАЙЛ: loader.asm (Рабочий LBA-загрузчик, версия 4.0)
; =================================================================
[org 0x7c00]
BITS 16

start:
    ; 1. Инициализация (Только 16-бит)
    cli                      
    
    ; Установка сегментных регистров в 0
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    ; Установка 16-битного стека
    mov sp, 0x7c00           

    ; 2. Настройка LBA чтения (AH=0x42)
    
    ; Функция AH=0x42, Диск DL=0x80
    mov ah, 0x42             
    mov dl, 0x80             
    
    ; Указатель на DAP (DS:SI = 0x0000:dap_address)
    mov si, dap_address      
    
    ; 3. Выполнение LBA чтения
    int 0x13                 
    
    ; Проверка ошибки (CF установлен при ошибке)
    jc disk_error            

    ; 4. Включение Protected Mode
    
    ; Загрузка GDT
    lgdt [gdt_descriptor]    

    ; Включение бита PE в CR0 (Используем EBX, чтобы не нарушать BITS 16)
    mov ebx, cr0             
    or ebx, 0x1
    mov cr0, ebx

    ; 5. Дальний переход в 32-битный режим
    ; !!! КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: ПРИНУДИТЕЛЬНО 32-БИТНЫЙ ОПЕРАНД
    o32 jmp 0x08:pm_start  ; jmp с 32-битным смещением 
                           ; Селектор 0x08 (Code), Смещение pm_start
; -----------------------------------------------------------------
; --- Код в Protected Mode ---
; -----------------------------------------------------------------
BITS 32
pm_start:
    ; 6. Установка 32-битных сегментных регистров
    mov ax, 0x10             ; 0x10 - селектор сегмента данных
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax           

    ; 7. Переход к точке входа ядра C (абсолютный адрес 0x10000)
    jmp 0x08:0x10000         

; -----------------------------------------------------------------
; --- Данные (Data Area) ---
; -----------------------------------------------------------------

; Структура DAP
dap_address:
.size:              db 0x10          
.count:             db 20            
.reserved:          dw 0             
.buffer_offset:     dw 0x0000        
.buffer_segment:    dw 0x1000        ; ES:BX = 0x1000:0x0000 = 0x10000
.target_lba:        dd 0x00000001    
.target_lba_high:   dd 0x00000000

; Global Descriptor Table (GDT)
gdt_start:
    dd 0x0, 0x0                      
    
    ; 0x08: Code Segment Descriptor
    dw 0xFFFF, 0x0, 0x0
    db 0x9A, 0xCF, 0x0
    
    ; 0x10: Data Segment Descriptor
    dw 0xFFFF, 0x0, 0x0
    db 0x92, 0xCF, 0x0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1       
    dd gdt_start + 0x7C00            

; -----------------------------------------------------------------
; --- Ошибка диска (16-бит) ---
; -----------------------------------------------------------------
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

disk_error_msg db "Disk Read Error! (LBA)", 0xD, 0xA, 0

; -----------------------------------------------------------------
; --- Завершение MBR ---
; -----------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xaa55