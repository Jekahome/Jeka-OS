.PHONY: all build-gcc kernel-layout assembling-kernel-entry convert-kernel-to-raw assembling-bootloader-asm create-disk-image clear run-qemu run-bochs check-size check-bootloader

# Главная цель: Полная сборка, диагностика и запуск
all: clear assembling-kernel-entry build-gcc kernel-layout convert-kernel-to-raw assembling-bootloader-asm create-disk-image check-size check-bootloader run-bochs

# --------------------------------------------------------
# Build kernel components
# --------------------------------------------------------
assembling-kernel-entry:
	nasm -f elf kernel_entry.asm -o kernel_entry.o

build-gcc:
	# Используем -march=i386 для предотвращения генерации современных инструкций
	i686-elf-gcc -m32 -ffreestanding -c kernel.c -o kernel.o -march=i386

# --------------------------------------------------------
# Linker and Conversion
# --------------------------------------------------------
# Шаг 1: Компоновка ELF-файла
kernel-layout:
	i686-elf-ld -m elf_i386 -T linker.ld kernel_entry.o kernel.o -o kernel_with_headers.elf

# Шаг 2: КРИТИЧЕСКИЙ ШАГ - Преобразование ELF в чистый бинарный формат
convert-kernel-to-raw: kernel-layout
	i686-elf-objcopy -O binary kernel_with_headers.elf kernel.bin

# --------------------------------------------------------
# Build bootloader
# --------------------------------------------------------
assembling-bootloader-asm:
	nasm -f bin loader.asm -o loader.bin

# --------------------------------------------------------
# Create final floppy image (!!! always 1.44MB !!!)
# --------------------------------------------------------
create-disk-image: convert-kernel-to-raw assembling-bootloader-asm
	cat loader.bin kernel.bin > os_image.bin # Объединение загрузчика и чистого бинарного ядра
	truncate -s 1474560 os_image.bin # Паддинг до 1.44MB
	chmod 644 os_image.bin

# --------------------------------------------------------
# Diagnostic and Run
# --------------------------------------------------------
check-size:
	@echo "Sizes:"
	ls -l loader.bin kernel.bin os_image.bin

check-bootloader:
	@echo "MBR signature:"
	# Проверка сигнатуры MBR (последние 2 байта = 0x55AA)
	dd if=os_image.bin bs=512 count=1 2>/dev/null | tail -c 2 | hexdump -C

run-qemu:
	qemu-system-i386 -drive file=os_image.bin,format=raw,if=floppy -boot a
	# qemu-system-i386 -fda os_image.bin -boot a
	# qemu-system-i386 -drive file=os_image.bin,format=raw,if=floppy -boot a -no-reboot
	# qemu-system-i386 -fda $(shell pwd)/os_image.bin -boot a -no-reboot
	# Запуск QEMU в режиме i386
	# qemu-system-i386 -drive file=os_image.bin,format=raw,if=floppy -boot a
	# Мы убрали -no-reboot, так как код работает, но оставили его на всякий случай ниже
	# qemu-system-i386 -drive file=os_image.bin,format=raw,if=floppy -boot a -no-reboot

run-bochs:
	bochs -f bochsrc.txt -q

# --------------------------------------------------------
# Util
# --------------------------------------------------------
clear:
	# Удаление всех промежуточных файлов
	rm -f kernel.o kernel_entry.o kernel_with_headers.elf kernel.bin loader.bin os_image.bin

help:
	@echo "Targets:"
	@echo "  make       - full build, diagnostics, and run"
	@echo "  make clear - clean files"
	@echo "  make run-qemu - run system"