#define VIDEO_START 0xB8000
#define VIDEO_SIZE 32*1000*8
#define VGA_FIRST_READABLE_COLOR 2
#define VGA_LAST_COLOR 5
#define VGA_LIGHT_GREY 7
static unsigned char * clearScreen(void) {
  for (int i = 0; i < VIDEO_SIZE; i++) {
    *((unsigned char *) VIDEO_START + i) = 0;
  }
  return (unsigned char *) VIDEO_START;
}

static unsigned char * rainbowPrint(char *str, unsigned char *video) {
  int color = VGA_FIRST_READABLE_COLOR;
  while (*str != '\0') {
    *(video++) = *str++;
    *(video++) = color;

    color++;
    if (color > VGA_LAST_COLOR)
      color = VGA_FIRST_READABLE_COLOR;
  }

  return video;
}

static unsigned char * print(char *str, unsigned char *video) {
  while (*str != '\0') {
    *(video++) = *str++;
    *(video++) = VGA_LIGHT_GREY;
  }
  return video;
}


void kmain(void) {
  unsigned char *video = clearScreen();
  video = print("This kernel prints ", video);
  video = rainbowPrint("rainbow", video);
  video = print(" text!", video);
  // This should work for interrupts:
  // asm volatile ("int $0x3");
  while(1);
}
