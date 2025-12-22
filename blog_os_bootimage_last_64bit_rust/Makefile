
# #####################################################
# ############  You need pre-install:  ################
#                                                     #
# rustup install nightly                              #
# rustup component add rust-src                       #
# cargo install bootimage                             #
# rustup component add llvm-tools-preview             #  
# sudo apt update && sudo apt install qemu-system-x86 #
# #####################################################


.PHONY: all clean build run-bios run-uefi

# Основная цель: собрать всё
all: clean build run-bios 

# Компиляция Rust-кода 
build:
	cargo build 

clean: 
	cargo clean

run-bios:
	cargo run bios

run-uefi:
	cargo run uefi
