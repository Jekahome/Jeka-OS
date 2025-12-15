/* boot.s - Multiboot2 Header */
.section .multiboot2
.align 8
mb2_header_start:
    .long 0xE85250D6       # magic
    .long 0                # architecture (0 = i386)
    .long mb2_header_end - mb2_header_start  # total length
    .long -(0xE85250D6 + 0 + (mb2_header_end - mb2_header_start))  # checksum

# END tag
.align 8
mb2_header_end:
    .long 0  # type = END
    .long 8  # size = 8

# простой стек
.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

.section .text
.global _start
.type _start, @function
_start:
    mov $stack_top, %esp
    call kernel_main
    cli
1:  hlt
    jmp 1b
.size _start, .-_start
