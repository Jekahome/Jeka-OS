/* ============================================================
 * boot.s — Multiboot2 + переход в x86_64 long mode
 * ============================================================
 */

.set MBOOT_HEADER_MAGIC,    0xe85250d6
.set MBOOT_HEADER_ARCH,     0          /* i386 */
.set MBOOT_HEADER_LENGTH,   header_end - header_start
.set MBOOT_HEADER_CHECKSUM, -(MBOOT_HEADER_MAGIC + MBOOT_HEADER_ARCH + MBOOT_HEADER_LENGTH)

/* ============================================================
 * Multiboot2 header (32-bit)
 * ============================================================
 */
.section .multiboot2
.align 8
header_start:
    .long MBOOT_HEADER_MAGIC
    .long MBOOT_HEADER_ARCH
    .long MBOOT_HEADER_LENGTH
    .long MBOOT_HEADER_CHECKSUM

    /* End tag */
    .word 0
    .word 0
    .long 8
header_end:

/* ============================================================
 * 32-bit boot code
 * ============================================================
 */
.section .text.boot
.code32
.global _start

_start:
    cli
    mov $stack_top, %esp

    /* --------------------------------------------------------
     * Setup paging structures
     * --------------------------------------------------------
     */
    call setup_paging

    /* --------------------------------------------------------
     * Enable PAE
     * --------------------------------------------------------
     */
    mov %cr4, %eax
    or  $0x20, %eax         # CR4.PAE = 1
    mov %eax, %cr4

    /* --------------------------------------------------------
     * Load PML4 into CR3
     * --------------------------------------------------------
     */
    mov $pml4_table, %eax
    mov %eax, %cr3

    /* --------------------------------------------------------
     * Enable Long Mode (EFER.LME)
     * --------------------------------------------------------
     */
    mov $0xC0000080, %ecx
    rdmsr
    or  $0x100, %eax
    wrmsr

    /* --------------------------------------------------------
     * Minimal GDT
     * --------------------------------------------------------
     */
    lgdt gdt_descriptor

    /* --------------------------------------------------------
     * Enable paging + protected mode
     * --------------------------------------------------------
     */
    mov %cr0, %eax
    or  $0x80000001, %eax    # PG + PE
    mov %eax, %cr0

    /* --------------------------------------------------------
     * Far jump to 64-bit code
     * --------------------------------------------------------
     */
    ljmp $0x08, $_start64


/* ============================================================
 * 64-bit code
 * ============================================================
 */
.section .text
.code64
_start64:
    mov $stack_top, %rsp       # 64-bit stack
    call kernel_main           # Rust entry point

.hang:
    hlt
    jmp .hang


/* ============================================================
 * Paging (identity map first 2MB)
 * ============================================================
 */
.section .bss
.align 4096
pml4_table:
    .skip 4096
pdpt_table:
    .skip 4096
pd_table:
    .skip 4096

.section .text
.code32
setup_paging:
    # PML4[0] = pdpt_table | 0x3
    movl $pdpt_table, %eax
    orl  $0x3, %eax
    movl %eax, pml4_table

    # PDPT[0] = pd_table | 0x3
    movl $pd_table, %eax
    orl  $0x3, %eax
    movl %eax, pdpt_table

    # PD[0] = 2MB page (identity map)
    movl $0x00000083, %eax
    movl %eax, pd_table

    ret


/* ============================================================
 * Stack
 * ============================================================
 */
.section .bss.stack,"aw",@nobits
.align 16
stack_bottom:
    .skip 65536
stack_top:

/* ============================================================
 * Minimal GDT for long mode
 * ============================================================
 */
.section .data
.align 8
gdt64:
    .quad 0x0000000000000000    # Null
    .quad 0x00AF9A000000FFFF    # Code segment (64-bit)
    .quad 0x00AF92000000FFFF    # Data segment

gdt_descriptor:
    .word gdt64_end - gdt64 - 1
    .quad gdt64

gdt64_end:
