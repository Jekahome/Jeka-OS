// =================================================================
// ФАЙЛ: kernel.c (32-битный Protected Mode)
// =================================================================
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

// Указатель на начало видеопамяти
volatile unsigned char* vga_buffer = (volatile unsigned char*)0xB8000;
int current_cursor_pos = 0;
const unsigned char DEFAULT_COLOR = 0x0A; // Светло-зеленый на черном

void clear_screen() {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i * 2] = ' ';         
        vga_buffer[i * 2 + 1] = 0x1F;     // Белый на ЯРКО-СИНЕМ фоне
    }
    current_cursor_pos = 0;
}

void print_char(char c) {
    if (c == '\n') {
        current_cursor_pos = (current_cursor_pos / VGA_WIDTH + 1) * VGA_WIDTH;
        return;
    }

    if (current_cursor_pos >= VGA_WIDTH * VGA_HEIGHT) {
        current_cursor_pos = 0;
        clear_screen(); 
    }

    vga_buffer[current_cursor_pos * 2] = c;
    vga_buffer[current_cursor_pos * 2 + 1] = DEFAULT_COLOR;

    current_cursor_pos++;
}

void print_string(const char* str) {
    int i = 0;
    while (str[i] != '\0') {
        print_char(str[i]);
        i++;
    }
}

// --- Точка входа в ядро ---
void kernel_main() {
    clear_screen();

    print_string("Welcome to your 32-bit OS (via QEMU)!\n");
    print_string("C Kernel initialized successfully at 0x10000.\n");
    print_string("Text should be GREEN on BLUE.\n");

    while (1) {
        asm("hlt");
    }
}