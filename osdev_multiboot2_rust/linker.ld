/* linker.ld - Линкерный скрипт для ядра i686 Multiboot2 */

/* Точка входа в ядро — функция _start из boot.o */
ENTRY(_start)

/* Для 32-битного x86 используем ELF-формат */
OUTPUT_FORMAT(elf32-i386)

/* Базовый адрес, с которого ядро будет загружено Multiboot-загрузчиком */
BASE_ADDRESS = 0x100000; /* 1 МБ */

SECTIONS
{
    /* Загрузочный код и Multiboot-заголовок */
    . = BASE_ADDRESS;
    .text :
    {
        KEEP(*(.multiboot2)) /* Удерживаем Multiboot2-заголовок */
        *(.text.boot)        /* Код из ассемблера (boot.s) */
        *(.text)             /* Весь остальной исполняемый код Rust */
        *(.text.*)
        . = ALIGN(4096);
    }

    /* Секция данных (инициализированные переменные) */
    .data :
    {
        *(.data)
        *(.data.*)
        . = ALIGN(4096);
    }

    /* Секция только для чтения данных (константы) */
    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4096);
    }

    /* Секция BSS (неинициализированные переменные, в т.ч. стек) */
    .bss :
    {
        /* Определяем стек, который мы зарезервировали в boot.s */
        . = ALIGN(16);
        stack_bottom = .;
        *(.bss.stack)
        *(.bss.*)
        *(.bss)
        . = ALIGN(16);
        stack_top = .;
    }

    /* Отбрасываем ненужные секции */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}