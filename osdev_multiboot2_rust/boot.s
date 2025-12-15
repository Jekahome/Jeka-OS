# boot.s

# =================================================================
# 1. MULTIBOOT2 HEADER
# =================================================================

.set MBOOT_HEADER_MAGIC, 0xe85250d6 
.set MBOOT_HEADER_ARCH,  0x00000000  # i386
.set MBOOT_HEADER_LENGTH, header_end - header_start

/* Сумма magic + arch + length, с отрицанием для получения 0 (контрольная сумма) */
.set MBOOT_HEADER_CHECKSUM, -(MBOOT_HEADER_MAGIC + MBOOT_HEADER_ARCH + MBOOT_HEADER_LENGTH)

.section .multiboot2
.align 8
header_start:
    .long MBOOT_HEADER_MAGIC
    .long MBOOT_HEADER_ARCH
    .long MBOOT_HEADER_LENGTH
    .long MBOOT_HEADER_CHECKSUM

    /* --- Теги (минимум - END TAG) --- */
    /* Обязательно: End Tag */
    .word 0x0000 # Type
    .word 0x0000 # Flags
    .long 0x0008 # Size (8 bytes)
header_end:


# =================================================================
# 2. CODE SECTION
# =================================================================

.section .text
.global _start
.type _start, @function
_start:
    # ... (Ваш код)
    mov $stack_top, %esp
    
    # Передаем magic (eax) и адрес структуры (ebx)
    push %ebx
    push %eax
    
    call kernel_main   # !!! Вызываем kernel_main
    
    cli
1:  hlt
    jmp 1b
.size _start, .-_start


# =================================================================
# 3. BSS SECTION (для стека)
# =================================================================
.section .bss.stack,"aw",@nobits
.align 4
stack_bottom:
    .skip 65536 # стек 16384 - 16KB, 65536 - 64KB
stack_top: