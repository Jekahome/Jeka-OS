/* linker.ld - Финальный скрипт для C++ ядра Multiboot2 (Адрес 2M) */

/* Точка входа в ядро (функция _start в boot.s) */
ENTRY(_start)

SECTIONS
{
    /* Устанавливаем счетчик размещения (location counter) на 2 мегабайта (0x200000).
       Это более безопасный адрес для загрузки в современных системах (UEFI). */
    . = 0x200000;

    /* 1. Секция .text (Код ядра) */
    .text BLOCK(4K) : ALIGN(4K)
    {
        /* Важно: Multiboot2 заголовок должен идти первым */
        KEEP(*(.multiboot2))

        /* Код boot.s и C++ ядра */
        *(.text)
        *(.text.*)
    }

    /* 2. Секция .rodata (Данные только для чтения) */
    .rodata BLOCK(4K) : ALIGN(4K)
    {
        *(.rodata)
        *(.rodata.*)
    }

    /* 3. Секции для глобальных конструкторов C++ */
    .init_array BLOCK(4K) : ALIGN(4K)
    {
        __init_array_start = .;
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
        KEEP(*(.init_array))
        __init_array_end = .;
    }

    /* 4. Секция .data (Инициализированные переменные) */
    .data BLOCK(4K) : ALIGN(4K)
    {
        *(.data)
        *(.data.*)
    }

    /* 5. Секция .bss (Неинициализированные переменные) */
    .bss BLOCK(4K) : ALIGN(4K)
    {
        __bss_start = .;
        *(COMMON)
        *(.bss)
        __bss_end = .;
    }

    /* Отбрасываем ненужные секции, такие как .eh_frame (для исключений) */
    /DISCARD/ :
    {
        *(.eh_frame)
    }
}