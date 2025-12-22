// src/lib.rs

#![no_std]
#![no_main]

use core::panic::PanicInfo;

/// Эта функция вызывается при возникновении паники
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

static HELLO: &[u8] = b"Hello World!";

#[no_mangle]
pub extern "C" fn kernel_main() -> ! {
    let vga_buffer_ptr = 0xb8000 as *mut u8;

    // Очистка экрана VGA
    // Цикл для очистки 80x25 символов (2000 ячеек * 2 байта/ячейка = 4000 байт)
    for i in 0..2000 {
        unsafe {
            // Записываем пробел (0x20)
            *vga_buffer_ptr.offset(i as isize * 2) = b' ';
            
        }
    } 

    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            *vga_buffer_ptr.offset(i as isize * 2) = byte;
            *vga_buffer_ptr.offset(i as isize * 2 + 1) = 0xb;// 0xb - светло-голубой
        }
    }

    loop {}
}

 