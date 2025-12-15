# =================================================================
# ФАЙЛ: Makefile (Сборка для QEMU)
# =================================================================

.PHONY: all clean run-qemu run-debug

all: clean os_image.bin run-qemu

clean:
	@echo "--- Удаление всех промежуточных файлов ---"
	rm -f kernel.o kernel_entry.o kernel_with_headers.elf kernel.bin loader.bin os_image.bin

run-qemu: 
	@echo "--- Размеры файлов ---"
	ls -l loader.bin kernel.bin os_image.bin
	@echo "--- Запуск QEMU ---"
	qemu-system-i386 -fda os_image.bin -boot a


run-debug: clean os_image.bin
	@echo "--- Запуск QEMU в режиме отладчика ---"
	qemu-system-i386 -fda os_image.bin -boot a -s -S

# --- Сборка ядра (32-бит) ---

kernel_entry.o: kernel_entry.asm
	nasm -f elf kernel_entry.asm -o kernel_entry.o

kernel.o: kernel.c
	i686-elf-gcc -m32 -ffreestanding -c kernel.c -o kernel.o -march=i386 -nostdlib  # ДОБАВЛЕН -nostdlib

kernel_with_headers.elf: kernel_entry.o kernel.o linker.ld
    # Линковка ассемблерной точки входа и C-кода
	i686-elf-ld -m elf_i386 -T linker.ld kernel_entry.o kernel.o -o kernel_with_headers.elf

kernel.bin: kernel_with_headers.elf
	i686-elf-objcopy -O binary kernel_with_headers.elf kernel.bin

# --- Сборка загрузчика (16-бит) ---

loader.bin: loader.asm
	nasm -f bin loader.asm -o loader.bin

# --- Создание образа ---

os_image.bin: loader.bin kernel.bin
    # Запись loader.bin (MBR) в первый сектор
	dd if=loader.bin of=os_image.bin bs=512 count=1 conv=notrunc
    # Запись kernel.bin во второй сектор (начиная со смещения 512)
	dd if=kernel.bin of=os_image.bin bs=512 seek=1 conv=notrunc
    # Паддинг
	truncate -s 1474560 os_image.bin
	chmod 644 os_image.bin