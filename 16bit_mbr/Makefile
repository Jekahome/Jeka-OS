# =================================================================
# ФАЙЛ: Makefile (16-битный Real Mode)
# =================================================================
AS = nasm

.PHONY: all clean run

all: clear os_image.bin run-qemu

 
clear:
	# Удаление всех промежуточных файлов
	rm -f kernel.o kernel_with_headers.elf kernel.bin loader.bin  

run-qemu:
	@echo "--- Проверка сигнатуры MBR (последние 2 байта = 0x55AA) ---"
	dd if=os_image.bin bs=512 count=1 2>/dev/null | tail -c 2 | hexdump -C
	qemu-system-i386 -drive file=os_image.bin,format=raw,if=floppy -boot a

# --- Сборка ядра (16-бит) ---

kernel.bin: kernel.asm
	$(AS) -f bin kernel.asm -o kernel.bin

# --- Сборка загрузчика (16-бит) ---

loader.bin: loader.asm
	$(AS) -f bin loader.asm -o loader.bin

# --- Создание образа ---

os_image.bin: loader.bin kernel.bin
	# Запись loader.bin (MBR) в первый сектор
	dd if=loader.bin of=os_image.bin bs=512 count=1 conv=notrunc
	# Запись kernel.bin во второй сектор (начиная со смещения 512)
	dd if=kernel.bin of=os_image.bin bs=512 seek=1 conv=notrunc
	# Паддинг
	truncate -s 1474560 os_image.bin
	chmod 644 os_image.bin