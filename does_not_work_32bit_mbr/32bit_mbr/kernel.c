// =================================================================
// ФАЙЛ: kernel.c (ИСПРАВЛЕННЫЙ: Яркий фон для отладки)
// =================================================================

// Константы VGA
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;

// Указатель на начало видеопамяти
volatile char* vga_buffer = (volatile char*)0xB8000;

// Глобальная переменная для отслеживания текущей позиции курсора
int current_cursor_pos = 0;

// Атрибут цвета по умолчанию (Светло-зеленый текст на черном фоне)
const char DEFAULT_COLOR = 0x0A; 

// --- Функция очистки экрана ---
void clear_screen() {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i * 2] = ' ';         // Символ
        // ИСПРАВЛЕНИЕ: Устанавливаем ЯРКИЙ фон (Белый на синем) для отладки
        // Если экран станет синим, значит, запись в VGA работает!
        vga_buffer[i * 2 + 1] = 0x1F;     
    }
    current_cursor_pos = 0;
}

// --- Функция вывода одного символа ---
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

// --- Функция вывода строки ---
void print_string(const char* str) {
    int i = 0;
    while (str[i] != '\0') {
        print_char(str[i]);
        i++;
    }
}

// --- Точка входа в ядро ---
// Гарантируем, что эта функция - первая в исполняемом коде
void kernel_main() __attribute__((section(".text.entry")));

void kernel_main() {
    // 1. Очистка экрана (должен стать синим)
    clear_screen();

    // 2. Вывод приветственного сообщения (должен быть светло-зеленым)
    print_string("Welcome to your custom 32-bit OS!\n");
    print_string("Kernel initialized successfully.\n");
    print_string("If you see this text, everything works.\n");

    // 3. Бесконечный цикл
    while (1) {
        asm("hlt");
    }
}