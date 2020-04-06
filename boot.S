/* *.S: run C preprocessor first. lowercase s means just assembly.
 * Sets up 64-bit paging data structures, sets CPU state for long mode */
#include "arch/x86_64/gdt.h"
#include "arch/x86_64/mmu.h"
#include "kernel.h"
#include "sizes.h"
#include "multiboot2.h"
#include "arch/x86_64/msr.h"
.SET HEADER_LENGTH, header_end - header_start
.SET CHECKSUM, -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + HEADER_LENGTH)

// Define the multiboot 2 header
.section .multiboot
header_start:
  .long MULTIBOOT2_HEADER_MAGIC
  .long MULTIBOOT_ARCHITECTURE_I386 // specify the architecture
  .long HEADER_LENGTH
  .long CHECKSUM

  // multiboot tags would go here
  .short MULTIBOOT_HEADER_TAG_END // required end tag, size of 1B
  .short 0 // flags, none are set
  .long 8   // size, including itself. short (2B) + short (2B) + long (4B) = 8B
header_end:

// Begin interpreting as 32-bit code
.code32

/* Declare variables (uninitialized) */
.section .bss
// Regions of memory for paging
.comm pml4, PML4_SIZE, PML4_ALIGNMENT
/* low page directory pointer table & page directory table
 * used for identity mapping */
.comm low_pdpt, PDPT_SIZE, PDPT_ALIGNMENT
.comm low_page_directory_table, PAGE_DIRECTORY_SIZE, PAGE_DIRECTORY_ALIGNMENT
/* high page directory pointer table & page directory table
 * used to map low physical memory to high virtual address */
.comm high_pdpt, PDPT_SIZE, PDPT_ALIGNMENT
.comm high_page_directory_table, PAGE_DIRECTORY_SIZE, PAGE_DIRECTORY_ALIGNMENT
.comm tmp_stack, KERNEL_BOOT_STACK_SIZE, KERNEL_BOOT_STACK_ALIGNMENT

// Declare initialized constants
.data

// Global descriptor table with two entries
.align GDT_TABLE_ALIGNMENT
gdt_table:
  .8byte GDT_FIRST_ENTRY
  .8byte GDT_CODE_ENTRY
  .8byte GDT_DATA_ENTRY
// Skip some space to give the GDT more space
gdt_table_end:
  .skip (GDT_TABLE_SIZE - (gdt_table_end - gdt_table))
// The pointer to the GDT table
gdt_ptr:
  .short GDT_TABLE_SIZE-1
  .long gdt_table // physical address of GDT

/* Start of boot assembly code */
.section .text
// GRUB jumps to _start, as specified in kernel.ld
.global _start
.type _start, @function
_start:
  /* Initialize declared variables */
  // Set stack
  movl $tmp_stack + KERNEL_BOOT_STACK_SIZE, %esp

  /* Set up pml4 entry for low_pdpt */
  movl $low_pdpt, %eax  // load PDPT address into %eax
  or $(MMU_PRESENT | MMU_WRITABLE), %eax  // or it, setting present and writable bits
  // move result into corresponding pml4 entry.
  movl %eax, pml4 + (PML4_ADDR_TO_ENTRY_INDEX(KERNEL_PHYSICAL_START) * PML4_ENTRY_SIZE)

  /* Set up pml4 entry for high_pdpt */
  movl $high_pdpt, %eax   // load PDPT address into eax
  or $(MMU_PRESENT | MMU_WRITABLE), %eax  // or it, setting present and writable bits
  // move result into corresponding pml4 entry
  movl %eax, pml4 + (PML4_ADDR_TO_ENTRY_INDEX(KERNEL_VIRTUAL_START) * PML4_ENTRY_SIZE)

  /* Similarly, for page directory tables */
  movl $low_page_directory_table, %eax
  or $(MMU_PRESENT | MMU_WRITABLE), %eax
  movl %eax, low_pdpt + (PDPT_ADDR_TO_ENTRY_INDEX(KERNEL_PHYSICAL_START) * PDPT_ENTRY_SIZE)

  movl $high_page_directory_table, %eax
  or $(MMU_PRESENT | MMU_WRITABLE), %eax
  movl %eax, high_pdpt + (PDPT_ADDR_TO_ENTRY_INDEX(KERNEL_VIRTUAL_START) * PDPT_ENTRY_SIZE)


  /* Loop to set up number of pages based on kernel_physical_end from kernel.ld */
  mov $0, %ecx  // contains current entry being set, so first set to 0

  movl $_kernel_physical_end, %esi  // load end address into esi
  shrl $TWO_MEGABYTES_SHIFT, %esi  // divide by two MB to get number of pages
  addl $1, %esi // add 1 to take care of rounding

  page_directory_table_loop:
    movl $TWO_MEGABYTES, %eax // load number representing 2 MB into eax
    mul %ecx  // multiply by current page being set to get addr
    or $(MMU_PRESENT | MMU_WRITABLE | MMU_PDE_TWO_MB), %eax // or with present, writable, 2 MB flags
    // store into page directory offset by ecx (counter) times size of page dir entry (8)
    movl %eax, low_page_directory_table(, %ecx, PAGE_DIRECTORY_ENTRY_SIZE)
    movl %eax, high_page_directory_table(, %ecx, PAGE_DIRECTORY_ENTRY_SIZE)

    inc %ecx  // done with current entry, increment counter
    cmp %esi, %ecx  // compare with number of pages we want to set up
    jne page_directory_table_loop  // if equal, exit. otherwise, set up next page.

  // move physical address of PML4 into cr3
  movl $pml4, %eax
  movl %eax, %cr3

  /* Set CPU state to transition into long mode */
  // 1. set up physical address extension bit (bit 5)
  movl $KERNEL_CR4, %eax
  movl %eax, %cr4

  // 2. Set up extended feature enable register model-specific register (EFER MSR)
  movl $MSR_EFER, %ecx
  rdmsr
  or $MSR_EFER_LME, %eax  // set bit 8 - enable long mode
  wrmsr

  // 3. Set up cr0 with bit 0 (protected mode), bit 4 (math coprocessor), bit 31 (paging)
  movl $KERNEL_CR0, %eax
  movl %eax, %cr0

  // Set global descriptor table (GDT)
  lgdt gdt_ptr

  // Long jump to _start64 - some 64-bit code in boot.S
  ljmp $(KERNEL_GDT_ENTRY * GDT_ENTRY_SIZE), $_start64

  // Shouldn't reach this point
  cli
  hlt

/* Begin interpreting as 64-bit code */
.code64

.global _start64
.type _start64, @function
_start64:
  // Set segment selectors to 0
  movw $0, %ax
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs
  movw %ax, %gs
  movw %ax, %ss

  // Go into the kernel main function
  call kmain

  // Shouldn't ever get to these instructions
  cli
  hlt
1:
  jmp 1b
