# =================================================================
# ФАЙЛ: Makefile (Использует полные команды) Multiboot1
# =================================================================

TARGET = myos.bin
ISODIR = isodir
ISONAME = myos.iso

.PHONY: all clean assemble-boot compile-kernel link-kernel check-kernel check-all check-kernel check-entry-adress

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

# Проверяет, содержит ли бинарник корректный Multiboot-заголовок
# Multiboot нужен, чтобы GRUB понимал, что это ядро и мог корректно его загрузить.
# Команда возвращает 0 → значит Multiboot заголовок найден.
# Если возвращает 1 → GRUB не видит Multiboot-заголовок → ядро не загрузится с CD/ISO
check-kernel:
	@echo "=== Check kernel Multiboot 1 header ==="
	@if grub-file --is-x86-multiboot myos.bin; then \
	    echo "✔ Kernel is multiboot compliant"; \
	else \
	    echo "✖ Kernel is NOT multiboot compliant"; exit 1; \
	fi

# Проверяет адрес точки входа (Entry Point) в исполняемом файле (ELF), для 1MB это адресс 0x00100000
check-entry-adress:
	@echo "=== Check kernel entry address ==="
	@ENTRY=$$(readelf -h myos.bin | grep 'Entry' | awk '{print $$4}'); \
	echo "Entry point address: $$ENTRY"; \
	if [ "$$ENTRY" = "0x00100000" ] || [ "$$ENTRY" = "0x10000c" ]; then \
		echo "✔ Entry address is correct (~1MB)"; \
	else \
		echo "✖ Entry address is unusual, should be ~0x00100000"; \
	fi

check-all: check-kernel check-entry-adress

# --- Шаг создания ISO ---
iso:  
	mkdir -p $(ISODIR)/boot/grub
	cp $(TARGET) $(ISODIR)/boot/$(TARGET)
	cp grub.cfg $(ISODIR)/boot/grub/grub.cfg
# grub-mkrescue использует лицензию GNU GPL !
	grub-mkrescue -o $(ISONAME) $(ISODIR) 

# --- Шаг запуска (Опционально) ---
run-qemu-kernel:
	qemu-system-i386 -kernel $(TARGET)

run-qemu-cdrom:
	qemu-system-i386 -cdrom $(ISONAME)

run-bochs:
	bochs -f bochsrc.txt -q

help:
	@echo "Use:"
	@echo "  make                      - full build"
	@echo "  make run-qemu-kernel      - run qemu, имитирует работу загрузчика GRUB"
	@echo "  make run-qemu-cdrom       - run qemu CD-ROM"