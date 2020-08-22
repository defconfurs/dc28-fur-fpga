##
## Make and program DC28 Fur Badge
##
TARGETNAME = dc28-fur-fpga
PROJTOP = top
PIN_DEF = Prototype2_hardware.pcf
DEVICE = up5k
PACKAGE = sg48

RTL_USB_DIR = usb/
RTL_USB_SRCS = \
    $(RTL_USB_DIR)/edge_detect.v \
    $(RTL_USB_DIR)/strobe.v \
    $(RTL_USB_DIR)/usb_fs_in_arb.v \
    $(RTL_USB_DIR)/usb_fs_in_pe.v \
    $(RTL_USB_DIR)/usb_fs_out_arb.v \
    $(RTL_USB_DIR)/usb_fs_out_pe.v \
    $(RTL_USB_DIR)/usb_fs_pe.v \
    $(RTL_USB_DIR)/usb_fs_rx.v \
    $(RTL_USB_DIR)/usb_fs_tx_mux.v \
    $(RTL_USB_DIR)/usb_fs_tx.v \
    $(RTL_USB_DIR)/usb_dfu_app_ep.v \
    $(RTL_USB_DIR)/usb_dfu_core.v \
    $(RTL_USB_DIR)/usb_phy_ice40.v

#############################
## Genetic Synthesis Rules
#############################
%.json: %.v
    yosys -q -p 'synth_ice40 -top $* -json $@' $(filter %.v,$^)

%.asc: %.json
    nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
        --pcf $(filter %.pcf, $^) --opt-timing \
        --json $(filter %.json, $^) --asc $@

%.bin: %.asc
    icepack $< $@

%.rpt: %.asc
    icetime -d $(DEVICE) -mtr $@ $<

#############################
## Badge Application Image
#############################
top.asc: $(PIN_DEF)
top.json: $(RTL_USB_SRCS) $(wildcard *.v)
top.json: brightness_lut_rom.txt filter_bank_mem.txt

TARGETS += top.bin

# Generated file contents.
brightness_lut_rom.txt filter_bank_mem.txt &: generate_luts.py
    python3 generate_luts.py

#############################
## Bootloaders
#############################
bootloader/firstboot.bin: bootloader
bootloader/tinydfu.bin: bootloader

bootloader:
    make -C bootloader

multiboot.bin: bootloader/firstboot.bin bootloader/tinydfu.bin top.bin
    icemulti -v -o $@ -a15 -p0 $^

TARGETS += multiboot.bin

all: bootloader
.PHONY: bootloader

#############################
## Common Make Targets
#############################
.DEFAULT_GOAL = all
.SECONDARY:
.PHONY: all prog clean

prog: multiboot.bin
    iceprog -p $<

all: $(TARGETS)

clean:
    make -C bootloader clean
    rm -f $(TARGETS) $(TARGETS:.bin=.json) $(TARGETS:.bin=.asc) $(TARGETS:.bin=.rpt)
    rm -f brightness_lut_rom.txt filter_bank_mem.txt
