# Makefile для blog_os_bootimage_last2_64bit_rust

# --- Пути ---
KERNEL=target/x86_64-unknown-none/release/kernel
BIOS_IMG=target/release/bios.img
UEFI_IMG=target/release/uefi.img

# --- OVMF (СИСТЕМНЫЙ) ---
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS=/usr/share/OVMF/OVMF_VARS_4M.fd

# Cargo и target
CARGO_NIGHTLY=cargo +nightly
TARGET=x86_64-unknown-none

# --- Основная цель ---
all: build-kernel build-bios build-uefi

# --- Сборка ядра ---
build-kernel:
	$(CARGO_NIGHTLY) build -Z build-std=core,alloc --target $(TARGET) --release -p kernel

# --- BIOS образ ---
build-bios: build-kernel
	$(CARGO_NIGHTLY) run -p create_images --release -- bios $(KERNEL) $(BIOS_IMG)

# --- UEFI образ ---
build-uefi: build-kernel
	$(CARGO_NIGHTLY) run -p create_images --release -- uefi $(KERNEL) $(UEFI_IMG)

# --- Запуск BIOS ---
run-bios: $(BIOS_IMG)
	qemu-system-x86_64 \
		-serial mon:stdio \
		-display gtk \
		-device isa-debug-exit,iobase=0xf4,iosize=0x04 \
		-drive format=raw,file=$(BIOS_IMG)

# --- Запуск UEFI (ВАЖНО) ---
run-uefi: $(UEFI_IMG)
	qemu-system-x86_64 \
		-serial mon:stdio \
		-display gtk \
		-device isa-debug-exit,iobase=0xf4,iosize=0x04 \
		-drive format=raw,file=$(UEFI_IMG) \
		-drive if=pflash,format=raw,unit=0,file=$(OVMF_CODE),readonly=on \
		-drive if=pflash,format=raw,unit=1,file=$(OVMF_VARS),snapshot=on \
		-no-reboot

# --- Очистка ---
clean:
	rm -rf $(BIOS_IMG) $(UEFI_IMG)
	$(CARGO_NIGHTLY) clean
