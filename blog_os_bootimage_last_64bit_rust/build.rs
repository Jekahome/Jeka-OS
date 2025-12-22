use std::path::PathBuf;

fn main() {
    // Заданные по cargo, скрипты сборки должны использовать эту папку для выходных файлов
    let out_dir = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());
    // Задаётся по функции зависимости от артефактов в Cargo, см.
    // https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#artifact-dependencies
    let kernel = PathBuf::from(std::env::var_os("CARGO_BIN_FILE_KERNEL_kernel").unwrap());

    // создать образ диска UEFI (по желанию)
    let uefi_path = out_dir.join("uefi.img");
    bootloader::UefiBoot::new(&kernel)
        .create_disk_image(&uefi_path)
        .unwrap();

    // создать образ диска BIOS
    let bios_path = out_dir.join("bios.img");
    bootloader::BiosBoot::new(&kernel)
        .create_disk_image(&bios_path)
        .unwrap();

    // передайте пути образа диска как переменные env к:
    println!("cargo:rustc-env=UEFI_PATH={}", uefi_path.display());
    println!("cargo:rustc-env=BIOS_PATH={}", bios_path.display());
}