# =================================================================
# ФАЙЛ: Makefile (C++ Multiboot2)
# =================================================================

TARGET = myos.bin
ISODIR = isodir
ISONAME = myos.iso

# Флаги компиляции C++: отключаем исключения и RTTI
CXXFLAGS = -std=gnu++17 -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti

.PHONY: all clean assemble-boot compile-kernel link-kernel check-kernel check-all iso run-qemu-cdrom

# Основная цель: собрать всё
all: clean assemble-boot compile-kernel link-kernel iso check-all

# Очистка
clean:
	rm -rf *.o $(TARGET) $(ISODIR) $(ISONAME) tmp.iso tmp_grub

# 1. Сборка boot.s
assemble-boot:
	i686-elf-as boot.s -o boot.o

# 2. Компиляция kernel.cpp
# Используем C++ компилятор и флаги CXXFLAGS
compile-kernel:
	i686-elf-g++ -c kernel.cpp $(CXXFLAGS) -o kernel.o

# 3. Линковка (Сборка myos.bin)
# Используем C++ линковщик, флаг -nostdlib и -lgcc для базовой поддержки компилятора
link-kernel:
	i686-elf-g++ -T linker.ld -o $(TARGET) $(CXXFLAGS) -nostdlib boot.o kernel.o -lgcc

# Проверяет, содержит ли бинарник корректный Multiboot2-заголовок
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
	cp $(TARGET) $(ISODIR)/boot/$(TARGET)        # Копируем myos.bin
	cp grub.cfg $(ISODIR)/boot/grub/grub.cfg     # Копируем grub.cfg
	grub-mkrescue -o $(ISONAME) $(ISODIR)

# --- Запуск QEMU с CD-ROM ---
run-qemu-cdrom:
	qemu-system-i386 -cdrom $(ISONAME)

help:
	@echo "Use:"
	@echo "  make                      - full build"
	@echo "  make run-qemu-cdrom       - run qemu CD-ROM"

