#![no_std]
#![no_main]
/*
bootloader_api — это удобная обёртка, которая экономит время: она уже реализует получение BootInfo, 
информации о видеопамяти (FrameBufferInfo) и упрощает работу с памятью

Вот что на самом деле делает bootloader_api:
* BootInfo — просто структура с указателями на память, фреймбуфер, карту памяти, RSDP, таблицы и т.д.
* FrameBufferInfo — структура с указателем на буфер, шириной, высотой, stride, pixel format и прочее.
* Методы типа fb.buffer_mut() или fb.info() — это просто безопасные обёртки над сырыми указателями и структурой.

Без bootloader_api:
Нужно реализовать все вручную: framebuffer, вывод текста/графики, карту памяти, возможно GDT, загрузчик сегментов и т.д.
*/
use bootloader_api::{entry_point, BootInfo, info::FrameBufferInfo};

entry_point!(kernel_main);

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

// ---------------------------------------------------------
// Шрифт 8x8, базовые символы
// ---------------------------------------------------------
pub static FONT8X8: [[u8;8];128] = {
    let mut f = [[0u8;8];128];
    f[b'H' as usize] = [0x18,0x18,0x3C,0x66,0x66,0x7E,0x66,0x66];
    f[b'e' as usize] = [0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00];
    f[b'l' as usize] = [0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x0C,0x00];
    f[b'o' as usize] = [0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00];
    f[b' ' as usize] = [0;8];
    f[b'W' as usize] = [0x00,0x00,0x66,0x66,0x66,0x7E,0x3C,0x00];
    f[b'r' as usize] = [0x00,0x00,0x6C,0x76,0x60,0x60,0xF0,0x00];
    f[b'd' as usize] = [0x0C,0x0C,0x3C,0x6C,0x6C,0x6C,0x3E,0x00];
    f[b'!' as usize] = [0x0C,0x0C,0x0C,0x0C,0x0C,0x00,0x0C,0x00];
    f
};

// ---------------------------------------------------------
// Работа с FrameBuffer
// ---------------------------------------------------------
fn put_pixel(buf: &mut [u8], info: &FrameBufferInfo, x: usize, y: usize, color: [u8;3]) {
    if x >= info.width as usize || y >= info.height as usize { return; }
    let idx = y * info.stride as usize * info.bytes_per_pixel as usize + x * info.bytes_per_pixel as usize;
    buf[idx] = color[2];
    buf[idx+1] = color[1];
    buf[idx+2] = color[0];
}

fn draw_char(buf: &mut [u8], info: &FrameBufferInfo, x: usize, y: usize, ch: u8, color: [u8;3]) {
    let glyph = &FONT8X8[ch as usize];
    for row in 0..8 {
        for col in 0..8 {
            if (glyph[row] >> (7-col)) & 1 != 0 {
                put_pixel(buf, info, x+col, y+row, color);
            }
        }
    }
}

fn draw_text(buf: &mut [u8], info: &FrameBufferInfo, x: usize, y: usize, text: &str, color: [u8;3]) {
    let mut cx = x;
    for b in text.bytes() {
        draw_char(buf, info, cx, y, b, color);
        cx += 8;
    }
}

fn clear_screen(buf: &mut [u8], info: &FrameBufferInfo, color: [u8;3]) {
    for y in 0..info.height as usize {
        for x in 0..info.width as usize {
            put_pixel(buf, info, x, y, color);
        }
    }
}

// ---------------------------------------------------------
// Точка входа ядра
// ---------------------------------------------------------
fn kernel_main(boot_info: &'static mut BootInfo) -> ! {
    let fb = boot_info.framebuffer.as_mut().unwrap();
    let info = fb.info().clone(); // <-- копируем инфо до mutable borrow
    let mut buf = fb.buffer_mut();

    clear_screen(&mut buf, &info, [0,0,0]);
    draw_text(&mut buf, &info, 50, 50, "Hello World!", [255,255,255]);

    loop {}
}
