#ifndef _ARCH_I386_MSR_H_
#define _ARCH_I386_MSR_H_

// MSR identifier for the Extended Feature Enable Register (EFER)
#define MSR_EFER 0xC0000080
// 8th bit enables long mode
#define MSR_EFER_LME (1 << 8)

#endif // _ARCH_I386_MSR_H_
