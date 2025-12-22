


 
# =================================================================
# ФАЙЛ: Makefile (Rust + Cargo, Multiboot2)
# =================================================================

TARGET = myos.bin
ISODIR = isodir
ISONAME = myos.iso

# ИСПОЛЬЗУЕМ RUST и КРОСС-ИНСТРУМЕНТЫ
RUST_TARGET = x86_64-unknown-none.json
CARGO_BUILD_DIR = target/x86_64-unknown-none/release

# Флаги линковки 
LDFLAGS = -nostdlib  

# Исходные файлы
BOOT_SRC = boot.s
BOOT_OBJ = boot.o

# Переменная окружения для указания, где найти исходники Rust (libcore)
RUST_SRC_PATH := $(shell rustc --print sysroot)/lib/rustlib/src/rust/library

.PHONY: all clean assemble-boot build-rust-lib link-kernel check-kernel \
check-all iso run-qemu-cdrom

# Основная цель: собрать всё
all: clean assemble-boot build-rust-lib link-kernel iso check-all

# Очистка
clean:
	rm -rf *.o $(TARGET) $(ISODIR) $(ISONAME) tmp.iso tmp_grub
	cargo clean # Очищаем выходные файлы Cargo

# 1. Сборка boot.s
assemble-boot:
	x86_64-elf-as $(BOOT_SRC) -o $(BOOT_OBJ)


# 2. Компиляция Rust-кода (создание статической библиотеки .a)
build-rust-lib:
    # Cargo собирает код как статическую библиотеку (.a)
	cargo build -Z unstable-options --target $(RUST_TARGET) --release

# 3. Линковка (Сборка myos.bin)
# Используем LD (x86_64-elf-ld), линкуем ассемблер, Rust-библиотеку и флаги
link-kernel: $(BOOT_OBJ) build-rust-lib
	x86_64-elf-ld -T linker.ld -o $(TARGET) $(BOOT_OBJ) $(CARGO_BUILD_DIR)/libmyos.a $(LDFLAGS)

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
	qemu-system-x86_64 -cdrom $(ISONAME)  

run-qemu-cdrom-debug:
	qemu-system-x86_64 -cdrom $(ISONAME) -boot d -m 512M -serial stdio -d int

help:
	@echo "Use:"
	@echo "  make                      - full build"
	@echo "  make run-qemu-cdrom       - run qemu CD-ROM"
	@echo "  make run-qemu-cdrom-debug - run qemu CD-ROM with debug"

	