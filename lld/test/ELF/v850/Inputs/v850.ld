/*
 * V850 Linker Script Template
 *
 * This is a generic template linker script for V850 microcontrollers.
 * Users must customize the MEMORY section for their specific device.
 *
 * Usage:
 *   ld.lld -T v850.ld input.o -o output.elf
 */

OUTPUT_FORMAT("elf32-v850", "elf32-v850", "elf32-v850")
OUTPUT_ARCH(v850)
ENTRY(_start)

/*
 * MEMORY SECTION - CUSTOMIZE FOR YOUR DEVICE
 *
 * Example configurations:
 *
 * V850E2/Fx4 (256KB ROM, 32KB RAM):
 *   ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
 *   RAM (rwx) : ORIGIN = 0xFEDE0000, LENGTH = 32K
 *
 * V850E2M (512KB ROM, 64KB RAM):
 *   ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 512K
 *   RAM (rwx) : ORIGIN = 0xFEDE0000, LENGTH = 64K
 *
 * RH850/F1L (2MB ROM, 128KB RAM):
 *   ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 2M
 *   RAM (rwx) : ORIGIN = 0xFEDE0000, LENGTH = 128K
 */
MEMORY
{
  /* Default: 256KB ROM, 32KB RAM - MODIFY FOR YOUR DEVICE */
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
  RAM (rwx) : ORIGIN = 0xFEDE0000, LENGTH = 32K
}

/* Stack and heap sizes - adjust as needed */
__stack_size = DEFINED(__stack_size) ? __stack_size : 0x1000;  /* 4KB default */
__heap_size  = DEFINED(__heap_size)  ? __heap_size  : 0x1000;  /* 4KB default */

SECTIONS
{
  /*
   * Reset and Exception Vectors
   * V850 exception table starts at 0x0000
   */
  .vectors : {
    KEEP(*(.vectors))
    KEEP(*(.reset))
  } > ROM

  /*
   * Code Section
   */
  .text : ALIGN(4) {
    *(.text.startup)
    *(.text.startup.*)
    *(.text)
    *(.text.*)
    *(.gnu.linkonce.t.*)
  } > ROM

  /*
   * Read-only Data
   */
  .rodata : ALIGN(4) {
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
  } > ROM

  /*
   * CALLT Table (V850E1+)
   * Must be 2-byte aligned, max 64KB from CTBP
   */
  .callt : ALIGN(2) {
    __callt_start = .;
    KEEP(*(.callt))
    __callt_end = .;
  } > ROM

  /*
   * Exception Handling (C++)
   */
  .eh_frame : {
    KEEP(*(.eh_frame))
  } > ROM

  .eh_frame_hdr : {
    *(.eh_frame_hdr)
  } > ROM

  /*
   * Init/Fini Arrays (C++ constructors/destructors)
   */
  .preinit_array : ALIGN(4) {
    PROVIDE_HIDDEN(__preinit_array_start = .);
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN(__preinit_array_end = .);
  } > ROM

  .init_array : ALIGN(4) {
    PROVIDE_HIDDEN(__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN(__init_array_end = .);
  } > ROM

  .fini_array : ALIGN(4) {
    PROVIDE_HIDDEN(__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN(__fini_array_end = .);
  } > ROM

  /* End of ROM sections */
  __rom_end = .;

  /*
   * Initialized Data
   * Loaded from ROM, copied to RAM at startup
   */
  .data : ALIGN(4) {
    __data_start = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    __data_end = .;
  } > RAM AT > ROM

  __data_load = LOADADDR(.data);

  /*
   * Small Data Area (SDA) - GP-relative
   * Accessible via GP (r4) with 16-bit signed displacement
   * Place frequently accessed small globals here
   */
  .sdata : ALIGN(4) {
    __sdata_start = .;
    __gp = . + 0x8000;  /* GP points to middle of SDA for ±32KB range */
    *(.sdata)
    *(.sdata.*)
    *(.gnu.linkonce.s.*)
    __sdata_end = .;
  } > RAM AT > ROM

  __sdata_load = LOADADDR(.sdata);

  /*
   * Tiny Data Area (TDA) - EP-relative
   * Accessible via EP (r30) with 8-bit unsigned displacement
   * Maximum 256 bytes, for most frequently accessed data
   */
  .tdata : ALIGN(4) {
    __tdata_start = .;
    __ep = .;  /* EP points to start of TDA */
    *(.tdata)
    *(.tdata.*)
    __tdata_end = .;
  } > RAM AT > ROM

  __tdata_load = LOADADDR(.tdata);

  /* Verify TDA fits in 256 bytes */
  ASSERT(__tdata_end - __tdata_start <= 256, "TDA section exceeds 256 bytes")

  /*
   * Uninitialized Data (BSS)
   * Cleared to zero at startup
   */
  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  /*
   * Small BSS - part of SDA
   */
  .sbss (NOLOAD) : ALIGN(4) {
    __sbss_start = .;
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    __sbss_end = .;
  } > RAM

  /*
   * Heap
   */
  .heap (NOLOAD) : ALIGN(4) {
    __heap_start = .;
    . += __heap_size;
    __heap_end = .;
  } > RAM

  /*
   * Stack
   * Grows downward from __stack_end
   */
  .stack (NOLOAD) : ALIGN(4) {
    __stack_start = .;
    . += __stack_size;
    __stack_end = .;
  } > RAM

  /* Symbols for runtime */
  __ram_start = ORIGIN(RAM);
  __ram_end = ORIGIN(RAM) + LENGTH(RAM);
  __rom_start = ORIGIN(ROM);

  /* Discard unwanted sections */
  /DISCARD/ : {
    *(.note.*)
    *(.comment)
  }
}

/*
 * Provide default symbols if not defined elsewhere
 */
PROVIDE(_start = __rom_start);
PROVIDE(__stack = __stack_end);
