use std::env;
use std::path::Path;
use bootloader::{BiosBoot, UefiBoot};

fn main() {
    let args: Vec<String> = env::args().collect();
    let mode = &args[1];           // "bios" или "uefi"
    let kernel_path = &args[2];    // путь к kernel
    let image_path = &args[3];     // путь к создаваемому образу

    if mode == "bios" {
        BiosBoot::new(Path::new(kernel_path))
            .create_disk_image(Path::new(image_path))
            .unwrap();
    } else if mode == "uefi" {
        UefiBoot::new(Path::new(kernel_path))
            .create_disk_image(Path::new(image_path))
            .unwrap();
    } else {
        panic!("Unknown mode: {}", mode);
    }
}
