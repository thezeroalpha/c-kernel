#ifndef _ARCH_X86_64_CONTROL_REGISTER_H_
#define _ARCH_X86_64_CONTROL_REGISTER_H_

/* control register 0 (cr0) - 32 bits, has control flags that modify basic operation of processor:
 * bit 31 - paging
 * bit 30 - cache disable
 * bit 29 - not write through
 * bit 18 - alignment mask
 * bit 16 - write protect
 * bit 5 - numeric error
 * bit 4 - extension type
 * bit 3 - task switched
 * bit 2 - emulation
 * bit 1 - monitor co-processor
 * bit 0 - protected mode enable
 */
#define CONTROL_REGISTER0_PROTECTED_MODE_ENABLED (1 << 0) // system is in protected mode
#define CONTROL_REGISTER0_EXTENSION_TYPE (1 << 4)
#define CONTROL_REGISTER0_PAGE (1 << 31)  // enable paging and use CR3 register

/* control register 4 (cr4) - used in protected mode, controls operations like virtual-8086 support,
 *  page size extension, and machine-check exceptions.
 *
 * the bits set here:
 *  bit 4 - page size extension. if 1, page size 4 MiB. if 0, page size 4 KiB.
 *  bit 5 - physical address extension. if 1, changes page table layout to translate 32-bit virt addr into extended 36-bit physical addr
 */
#define CONTROL_REGISTER4_PAGE_SIZE_EXTENSION (1 << 4)
#define CONTROL_REGISTER4_PHYSICAL_ADDRESS_EXTENSION (1 << 5)

#endif // _ARCH_X86_64_CONTROL_REGISTER_H_
