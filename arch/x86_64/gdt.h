#ifndef _ARCH_X86_64_GDT_H_
#define _ARCH_X86_64_GDT_H_

/* GDT - global descriptor table
 * has segment and size
 * each entry is 8 bytes:
 *  - 2 bytes size limit
 *  - 3 bytes segment pointer
 *  - 1 byte access rights
 *  - 1 byte (low bits limit, high bits flags)
 *  - 1 byte pointer
 */

// A GDT entry is 8 bytes
#define GDT_ENTRY_SIZE 8

#define LIMIT_4GB 0xFFFF

/* flags: [granularity, size, x86-64 code descriptor, 0]
 *  - granularity: 0 (limit is in 1B blocks, byte granularity), 1 (limit is in 4 KiB blocks, page granularity)
 *  - size: 0 (defines 16 bit protected mode), 1 (defines 32 bit protected mode)
 */
#define GDT_FLAG_4KB_GRANULARITY (1 << 3)

// 64bit flag for code segments, reserved bit for data segments!
#define GDT_FLAG_64BIT_MODE (1 << 1)

/* access bits: [present, privilege (2), descriptor type, executable bit, direction/conforming bit, readable/writable bit, accessed bit]
 *  - present: must be 1 for all valid selectors
 *  - privilege: two bits, contains ring level (0 highest for kernel, 3 lowest for user apps)
 *  - descriptor type: 1 for code/data segments, 0 for system segments
 *  - executable bit: 1 if code can be executed, 0 if data selector
 *  - direction/conforming bit:
 *    - direction for data: 0 grows up, 1 grows down
 *    - conforming for code: 1 if executable from equal or lower privilege, 0 if only executable from level in privilege bit
 *  - readable/writable bit:
 *    - readable for code selectors: whether read access allowed (write never allowed for code)
 *    - writable for data selectors: whether write access allowed (read always allowed for data)
 *  - accessed bit: just set to 0, CPU sets to 1 when it accesses it
 */
#define GDT_ACCESS_PRESENT (1 << 7)
#define GDT_ACCESS_PRIVILEGE_RING0 (0 << 5)
#define GDT_ACCESS_EXECUTABLE (1 << 3)
#define GDT_ACCESS_RWABLE (1 << 1)

// A macro that makes human-readable code into the terrible layout of GDT
#define DECLARE_GDT_ENTRY(base, limit, flags, access)                          \
  (                                                                            \
    (((((base)) >> 24) & 0xFF) << 56) |                                        \
    ((((flags)) & 0xF) << 52) |                                                \
    (((((limit)) >> 16) & 0xF) << 48) |                                        \
    (((((access) | (1 << 4))) & 0xFF) << 40) |                                 \
    ((((base)) & 0xFFF) << 16) |                                               \
    (((limit)) & 0xFFFF)                                                       \
  )

#define GDT_FIRST_ENTRY 0

#define GDT_CODE_ENTRY                                                         \
  DECLARE_GDT_ENTRY(0, LIMIT_4GB,                                              \
                    GDT_FLAG_64BIT_MODE,                                       \
                    GDT_FLAG_4KB_GRANULARITY |                                 \
                    GDT_ACCESS_PRESENT |                                       \
                    GDT_ACCESS_PRIVILEGE_RING0 |                               \
                    GDT_ACCESS_RWABLE |                                        \
                    GDT_ACCESS_EXECUTABLE)                                     \

#define GDT_DATA_ENTRY                                                         \
  DECLARE_GDT_ENTRY(0, LIMIT_4GB,                                              \
                    GDT_FLAG_4KB_GRANULARITY,                                  \
                    GDT_ACCESS_PRESENT |                                       \
                    GDT_ACCESS_PRIVILEGE_RING0 |                               \
                    GDT_ACCESS_RWABLE)

#define GDT_TABLE_ALIGNMENT 0x1000
#define GDT_TABLE_SIZE 0x800

#endif // _ARCH_X86_64_GDT_H_
