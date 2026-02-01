/*
 * V850 C Runtime Startup - crt0.S
 *
 * This is a minimal startup file for V850 microcontrollers.
 * It initializes the stack, pointers, and C runtime environment.
 *
 * Requires linking with a linker script that defines:
 *   __stack_end   - Top of stack
 *   __gp          - Global pointer (middle of SDA)
 *   __ep          - Element pointer (start of TDA)
 *   __bss_start   - Start of BSS section
 *   __bss_end     - End of BSS section
 *   __data_start  - Start of initialized data in RAM
 *   __data_end    - End of initialized data in RAM
 *   __data_load   - Start of initialized data in ROM
 *   __sdata_start - Start of small data in RAM
 *   __sdata_end   - End of small data in RAM
 *   __sdata_load  - Start of small data in ROM
 *
 * Usage:
 *   clang --target=v850 -mcpu=v850e2m -c crt0.S -o crt0.o
 *   ld.lld -T v850.ld crt0.o main.o -o program.elf
 */

    .section .reset, "ax"
    .global _start
    .type _start, @function

_start:
    /*
     * Initialize Stack Pointer (SP/r3)
     * Stack grows downward from __stack_end
     */
    movhi   __stack_end, r0, sp
    movea   __stack_end, sp, sp

    /*
     * Initialize Global Pointer (GP/r4)
     * Used for Small Data Area (SDA) access
     * Points to middle of .sdata/.sbss for +/-32KB range
     */
    movhi   __gp, r0, gp
    movea   __gp, gp, gp

    /*
     * Initialize Element Pointer (EP/r30)
     * Used for Tiny Data Area (TDA) access
     * Points to start of .tdata for 0-255 byte range
     */
    movhi   __ep, r0, ep
    movea   __ep, ep, ep

    /*
     * Initialize Thread Pointer (TP/r5)
     * Set to zero if not using TLS
     */
    mov     r0, tp

    /*
     * Clear BSS Section
     * Set all bytes in .bss and .sbss to zero
     */
    movhi   __bss_start, r0, r6     /* r6 = current address */
    movea   __bss_start, r6, r6
    movhi   __bss_end, r0, r7       /* r7 = end address */
    movea   __bss_end, r7, r7
    mov     r0, r8                   /* r8 = 0 (value to store) */
.Lclear_bss:
    cmp     r6, r7
    bge     .Lclear_bss_done        /* if (r6 >= r7) done */
    st.w    r8, 0[r6]               /* *r6 = 0 */
    addi    4, r6, r6               /* r6 += 4 */
    br      .Lclear_bss
.Lclear_bss_done:

    /* Clear small BSS */
    movhi   __sbss_start, r0, r6
    movea   __sbss_start, r6, r6
    movhi   __sbss_end, r0, r7
    movea   __sbss_end, r7, r7
.Lclear_sbss:
    cmp     r6, r7
    bge     .Lclear_sbss_done
    st.w    r8, 0[r6]
    addi    4, r6, r6
    br      .Lclear_sbss
.Lclear_sbss_done:

    /*
     * Copy Initialized Data from ROM to RAM
     * .data section: ROM (__data_load) -> RAM (__data_start)
     */
    movhi   __data_load, r0, r6     /* r6 = source (ROM) */
    movea   __data_load, r6, r6
    movhi   __data_start, r0, r7    /* r7 = destination (RAM) */
    movea   __data_start, r7, r7
    movhi   __data_end, r0, r8      /* r8 = end of destination */
    movea   __data_end, r8, r8
.Lcopy_data:
    cmp     r7, r8
    bge     .Lcopy_data_done        /* if (dest >= end) done */
    ld.w    0[r6], r9               /* r9 = *src */
    st.w    r9, 0[r7]               /* *dest = r9 */
    addi    4, r6, r6               /* src += 4 */
    addi    4, r7, r7               /* dest += 4 */
    br      .Lcopy_data
.Lcopy_data_done:

    /* Copy small data (.sdata) */
    movhi   __sdata_load, r0, r6
    movea   __sdata_load, r6, r6
    movhi   __sdata_start, r0, r7
    movea   __sdata_start, r7, r7
    movhi   __sdata_end, r0, r8
    movea   __sdata_end, r8, r8
.Lcopy_sdata:
    cmp     r7, r8
    bge     .Lcopy_sdata_done
    ld.w    0[r6], r9
    st.w    r9, 0[r7]
    addi    4, r6, r6
    addi    4, r7, r7
    br      .Lcopy_sdata
.Lcopy_sdata_done:

    /*
     * Call main()
     * Arguments: argc = 0, argv = NULL
     */
    mov     r0, r6                  /* argc = 0 */
    mov     r0, r7                  /* argv = NULL */
    jarl    main, lp                /* Call main() */

    /* main() returned - halt */
.Lexit:
    halt
    br      .Lexit                  /* Loop forever if halt returns */

    .size _start, . - _start


/*
 * Default Exception Handlers
 * These are weak symbols that can be overridden by user code
 */
    .section .text
    .weak _nmi_handler
    .weak _trap_handler
    .weak _default_handler

_nmi_handler:
_trap_handler:
_default_handler:
    br      .                       /* Infinite loop */


/*
 * Exception Vector Table
 * V850 vectors are at fixed addresses from 0x0000
 * Customize this for your specific device's interrupt sources
 */
    .section .vectors, "ax"

    /* 0x0000: Reset Vector */
    .org 0x0000
    jr      _start

    /* 0x0010: NMI (Non-Maskable Interrupt) */
    .org 0x0010
    jr      _nmi_handler

    /* 0x0020: INTWDT (Watchdog Timer) - device specific */
    .org 0x0020
    jr      _default_handler

    /* 0x0030-0x007F: Reserved for system exceptions */

    /* 0x0080+: Peripheral Interrupts - device specific */
    /* Add more vectors as needed for your device */

    .org 0x0080
    jr      _default_handler

    .org 0x0090
    jr      _default_handler

    .org 0x00A0
    jr      _default_handler

    .org 0x00B0
    jr      _default_handler

    .org 0x00C0
    jr      _default_handler

    .org 0x00D0
    jr      _default_handler

    .org 0x00E0
    jr      _default_handler

    .org 0x00F0
    jr      _default_handler

/*
 * End of crt0.S
 */
