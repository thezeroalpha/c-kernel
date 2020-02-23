/* Specify GRUB's entry point */
ENTRY(_start)

/* Describes memory layout of output file */
SECTIONS {
  /* Set size of current output location to 4 MB */
  . = 4M;

  /* Begin the kernel physical address space */
  _kernel_physical_start = .;

  /* First, the multiboot and text sections of file boot.o */
  .boottext : {
      boot.o (.multiboot)
      boot.o (.text)
    }

  /* Then, the rodata section of file boot.o */
  .bootrodata : {
      boot.o (.rodata)
    }

  /* Then, the data section of file boot.o */
  .bootdata : {
      boot.o (.data)
    }

  /* Then, the bss and COMMON sections of file boot.o */
  .bootbss : {
      boot.o (.bss)
      boot.o (COMMON)
    }

  /* End of the boot section, aligned to a KB */
  . = ALIGN(0x1000);
  _boot_end = .;

  /* Start virtual address space, i.e. give kernel the 0xFF..FF-0xFFF..000 addresses.
   * Kernel gets 2GB of space */
  . += 0xFFFFFFFF80000000;
  _kernel_virtual_start = .;

  /* Add the multiboot and text sections from any other input files */
  .text : AT(_boot_end) {
    *(.multiboot)
    *(.text)
  }

  . = ALIGN(0x1000);

  /* Add the rodata for any input files */
  .rodata : AT ( (LOADADDR (.text) + SIZEOF (.text) + 0xFFF) & 0xFFFFFFFFFFFFF000 ) {
    *(.rodata)
  }

  . = ALIGN(0x1000);

  /* Add the data section for any input files */
  .data : AT((LOADADDR(.rodata) + SIZEOF(.rodata) + 0xFFF) & 0xFFFFFFFFFFFFF000) {
    *(.data)
  }

  . = ALIGN(0x1000);

  /* Add the COMMON and bss sections for input files */
  .bss : AT ( (LOADADDR (.data) + SIZEOF (.data) + 0xFFF) & 0xFFFFFFFFFFFFF000 ) {
    *(COMMON)
    *(.bss)
  }

  /* End of the kernel's virtual address space */
  _kernel_virtual_end = .;

  /* End of the kernel's physical address space */
  _kernel_physical_end = (LOADADDR (.bss) + SIZEOF (.bss) + 0xFFF) & 0xFFFFFFFFFFFFF000;
}
