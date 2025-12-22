 
/* 
Для Multiboot2 GRUB передаёт структуру multiboot2_info_t, если вы хотите использовать карту памяти, но для минимального ядра это не обязательно. 
*/
 
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer = (uint16_t*)VGA_MEMORY;

enum vga_color { BLACK, BLUE, GREEN, CYAN, RED, MAGENTA, BROWN, LIGHT_GREY, DARK_GREY, LIGHT_BLUE, LIGHT_GREEN, LIGHT_CYAN, LIGHT_RED, LIGHT_MAGENTA, LIGHT_BROWN, WHITE };

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) { return fg | bg << 4; }
static inline uint16_t vga_entry(unsigned char uc, uint8_t color) { return (uint16_t) uc | (uint16_t) color << 8; }

size_t strlen(const char* str) { size_t len = 0; while (str[len]) len++; return len; }

void terminal_initialize(void) {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(LIGHT_GREY, BLACK);
    for (size_t y = 0; y < VGA_HEIGHT; y++)
        for (size_t x = 0; x < VGA_WIDTH; x++)
            terminal_buffer[y * VGA_WIDTH + x] = vga_entry(' ', terminal_color);
}

void terminal_putchar(char c) {
    if (c == '\n') { terminal_column = 0; if (++terminal_row == VGA_HEIGHT) terminal_row = 0; return; }
    terminal_buffer[terminal_row * VGA_WIDTH + terminal_column] = vga_entry(c, terminal_color);
    if (++terminal_column == VGA_WIDTH) { terminal_column = 0; if (++terminal_row == VGA_HEIGHT) terminal_row = 0; }
}

void terminal_writestring(const char* data) {
    for (size_t i = 0; i < strlen(data); i++)
        terminal_putchar(data[i]);
}

void kernel_main(void) {
    terminal_initialize();
    terminal_writestring("Hello, Multiboot2 World!\n");
}
