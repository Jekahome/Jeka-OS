//! src/main.rs

#![no_std] // не подключайте стандартную библиотеку Rust
#![no_main] // отключить все точки входа уровня Rust

use core::panic::PanicInfo;

/// Эта функция вызывается при возникновении паники
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

static HELLO: &[u8] = b"Hello World!";

#[unsafe(no_mangle)] // не искажайте название этой функцииle)]
pub extern "C" fn _start() -> ! {
    let vga_buffer = 0xb8000 as *mut u8;

    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0xb;// 0xb - светло-голубой
        }
    }

    // Эта функция является точкой входа, поскольку компоновщик ищет функцию.  
    // по умолчанию называется `_start`
    loop {}
}