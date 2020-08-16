##
## Make and program TinyFPGA BX
##
PIN_DEF = ../top.pcf
DEVICE = up5k
PACKAGE = sg48
TARGETS = 

RTL_USB_DIR = ../tinydfu-bootloader/usb/
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
	$(RTL_USB_DIR)/usb_reset_det.v \
	$(RTL_USB_DIR)/usb_dfu_ctrl_ep.v \
	$(RTL_USB_DIR)/usb_spiflash_bridge.v \
	$(RTL_USB_DIR)/usb_dfu_core.v \
	$(RTL_USB_DIR)/usb_phy_ice40.v

#############################
## Genetic Synthesis Rules
#############################
%.json: %.v
	yosys -q -p 'synth_ice40 -top $* -json $@' $(filter %.v,$^)

%.asc: %.json
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
		--pcf $(PIN_DEF) --opt-timing \
		--json $(filter %.json, $^) --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

#############################
## First Stage Bootloader
#############################
firstboot.asc: $(PIN_DEF)

TARGETS += firstboot.bin

#############################
## Second Stage TinyDFU
#############################
tinydfu.json: $(RTL_USB_SRCS) tinydfu_pll.v
tinydfu.asc: $(PIN_DEF)

tinydfu_pll.v:
	icepll -i 16 -o 48 -m -f $@

TARGETS += tinydfu.bin

#############################
## Common Make Targets
#############################
.DEFAULT_GOAL = all
.SECONDARY:
.PHONY: all clean

all: $(TARGETS)

clean:
	rm -f $(TARGETS) $(TARGETS:.bin=.json) $(TARGETS:.bin=.asc) $(TARGETS:.bin=.rpt)
	rm -f tinydfu_pll.v
