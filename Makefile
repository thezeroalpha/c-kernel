CC=gcc
SHARED_FLAGS = -fno-builtin -O2 -nostdinc -nostdlib -ffreestanding -g -Wall -Wextra \
			   -Werror -I. -MMD -mno-red-zone -mcmodel=kernel -fno-pie
CFLAGS = $(SHARED_FLAGS)
ASFLAGS = $(SHARED_FLAGS) -Wa,--divide

OBJS := boot.o
OBJS += kernel.o
ISO_FILE = kernel.iso

DFILES = $(patsubst %.o,%.d,$(OBJS))

all: kernel

kernel: $(OBJS) kernel.ld Makefile
	$(CC) -z max-page-size=0x1000 $(CFLAGS) -no-pie -Wl,--build-id=none -T kernel.ld -o $@ $(OBJS)

clean:
	find . -name "*~" -delete
	rm -rf $(OBJS) $(DFILES) kernel $(ISO_FILE) iso/

iso: kernel
	mkdir -p iso/boot/grub
	cp grub.cfg iso/boot/grub/
	cp kernel iso/boot/
	grub-mkrescue -o $(ISO_FILE) iso
run: iso
	qemu-system-x86_64 -cdrom $(ISO_FILE) -serial stdio -m 1024M
$(OBJS): Makefile
-include $(DFILES)
