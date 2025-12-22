# =================================================================
# ФАЙЛ: Makefile (Использует полные команды, Multiboot2)
# =================================================================

TARGET = myos.bin
ISODIR = isodir
ISONAME = myos.iso

.PHONY: all clean assemble-boot compile-kernel link-kernel check-kernel check-all iso run-qemu-cdrom help

# Основная цель: собрать всё
all: clean assemble-boot compile-kernel link-kernel iso check-all 

# Очистка
clean:
	rm -rf *.o $(TARGET) $(ISODIR) $(ISONAME)

# 1. Сборка boot.s
assemble-boot:
	i686-elf-as boot.s -o boot.o

# 2. Компиляция kernel.c
# Флаги:
# -c: только компиляция, без линковки
# -std=gnu99: использовать стандарт C99 с расширениями GNU
# -ffreestanding: окружение без стандартной библиотеки (ОС отсутствует)
# -O2: уровень оптимизации
# -Wall -Wextra: включить все предупреждения
compile-kernel:
	i686-elf-gcc -c kernel.c -std=gnu99 -ffreestanding -O2 -Wall -Wextra -o kernel.o

# 3. Линковка (Сборка myos.bin)
# Флаги:
# -T linker.ld: использовать скрипт линковщика
# -ffreestanding -O2 -nostdlib: те же флаги, что и для компилятора, плюс -nostdlib
#                               (не использовать стандартные библиотеки C при линковке)
link-kernel:
	i686-elf-gcc -T linker.ld -o $(TARGET) -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

# Проверяет, содержит ли бинарник корректный Multiboot2-заголовок
# Multiboot2 нужен, чтобы GRUB понимал, что это ядро и мог корректно его загрузить.
# Команда возвращает 0 → значит Multiboot2 заголовок найден.
# Если возвращает 1 → GRUB не видит Multiboot2-заголовок → ядро не загрузится с CD/ISO
check-kernel:
	@echo "=== Check kernel Multiboot 2 header ==="
	@if grub-file --is-x86-multiboot2 $(TARGET); then \
	    echo "✔ Kernel is multiboot2 compliant"; \
	else \
	    echo "✖ Kernel is NOT multiboot2 compliant"; exit 1; \
	fi

check-all: check-kernel  

# --- Шаг создания ISO ---
iso:
	mkdir -p $(ISODIR)/boot/grub
	cp $(TARGET) $(ISODIR)/boot/$(TARGET)
	cp grub.cfg $(ISODIR)/boot/grub/grub.cfg
# grub-mkrescue использует лицензию GNU GPL !
	grub-mkrescue -o $(ISONAME) $(ISODIR) 

# --- Альтернатива: запуск QEMU с CD-ROM ---
run-qemu-cdrom:
	qemu-system-i386 -cdrom $(ISONAME)

# Multiboot2 не предназначен для запуска с флагом -kernel  
# так как Multiboot2 не содержит PVH ELF Note — Paravirtualized HVM структуру

help:
	@echo "Use:"
	@echo "  make                      - full build"
	@echo "  make run-qemu-cdrom       - run qemu CD-ROM"
