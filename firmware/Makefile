
CROSS_COMPILE ?= riscv64-unknown-elf-
CFLAGS = -O2 -march=rv32ic -mabi=ilp32 -I .
CFLAGS += -DPRINTF_DISABLE_SUPPORT_FLOAT=1 -DPRINTF_DISABLE_SUPPORT_EXPONENTIAL=1
CFLAGS += -DPRINTF_DISABLE_SUPPORT_LONG_LONG=1 -DPRINTF_DISABLE_SUPPORT_PTRDIFF_T=1
LDFLAGS = $(CFLAGS) -Wl,-Bstatic,-T,firmware.lds,--gc-sections

OBJS = start.o main.o printf.o

# Pattern Rules
%.o: %.s
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -c -o $@ $<

%.bin: %.elf
	$(CROSS_COMPILE)objcopy -O binary $^ $@

%.mem: %.bin
	hexdump  -e '"" 1/4 "%08x\n"' $^ > $@

# Firmware Build Rules.
firmware.elf: $(OBJS)
	$(CROSS_COMPILE)gcc $(LDFLAGS) -o $@ $^

.DEFAULT_GOAL = all
.PHONY: all clean

all: firmware.mem

clean:
	rm -f *.o *.elf *.bin *.mem
