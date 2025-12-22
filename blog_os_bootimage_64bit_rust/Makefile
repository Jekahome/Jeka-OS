
# ###########################################
# ########  You need pre-install:  ##########
#                                           #
# rustup install nightly                    #
# rustup component add rust-src             #
# cargo install bootimage                   #
# rustup component add llvm-tools-preview   #  
#                                           #
# ###########################################

TARGET = bootimage-blog_os_bootimage_64bit_rust
TARGET_BIN = ${TARGET}.bin
PATH_TARGET_BIN = target/x86_64-blog_os_bootimage_64bit_rust/debug/${TARGET_BIN}


.PHONY: all clean build run-qemu-raw

# Основная цель: собрать всё
all: clean build run-qemu-raw

# Компиляция Rust-кода 
build:
	cargo bootimage 

clean: 
	cargo clean

run-qemu-raw:
	qemu-system-x86_64 -drive format=raw,file=$(PATH_TARGET_BIN)

