#!/usr/bin/python3
import os
import sys
import argparse
import subprocess
from subprocess import call
from glob import glob

srcdir = os.path.dirname(os.path.abspath(__file__))
libdir = os.path.join(srcdir, "lib")
firmwaredir = os.path.join(srcdir, "firmware")
ldsfile = os.path.join(firmwaredir,'firmware.lds')

CFLAGS = ['-Os', '-march=rv32i', '-mabi=ilp32', '-I', '.', '-I', firmwaredir]
CFLAGS += ['-ffunction-sections', '-fdata-sections', '--specs=nano.specs']
LDFLAGS = CFLAGS + ['-Wl,-Bstatic,-T,'+ldsfile+',--gc-sections']


#######################################
## FPGA Source Files
#######################################
pcf_file = "Prototype2_hardware.pcf"

# Common USB sources, shared by both the DFU bootloader and user bitstream.
rtl_usb_dir = os.path.join(srcdir, 'tinydfu-bootloader/usb')
rtl_usb_srcs = ["edge_detect.v",
                "strobe.v",
                "usb_fs_in_arb.v",
                "usb_fs_in_pe.v",
                "usb_fs_out_arb.v",
                "usb_fs_out_pe.v",
                "usb_fs_pe.v",
                "usb_fs_rx.v",
                "usb_fs_tx_mux.v",
                "usb_fs_tx.v",
                "usb_string_rom.v",
                "usb_phy_ice40.v"]

# DFU Bootloader sources.
dfu_usb_srcs = rtl_usb_srcs
dfu_usb_srcs += ["usb_dfu_core.v",
                "usb_dfu_ctrl_ep.v",
                "usb_spiflash_bridge.v"]

boot_srcs = [ os.path.join('bootloader', 'tinydfu.v'), 'pll48mhz.v' ]
boot_srcs += [ os.path.join(rtl_usb_dir, x) for x in dfu_usb_srcs ] 

# User Bitstream sources.
stub_usb_srcs = rtl_usb_srcs
stub_usb_srcs += ["usb_serial_core.v",
                  "usb_serial_ctrl_ep.v",
                  "usb_uart_in_ep.v",
                  "usb_uart_out_ep.v"]

lib_srcs = ["VexRiscv_Min.v",
            "wbcdecoder.v",
            "wbcxbar.v",
            "wbcrouter.v",
            "wb_qspi_flash.v"]

sources = glob(os.path.join(srcdir, '*.v'))
sources += [ os.path.join(rtl_usb_dir, x) for x in stub_usb_srcs ]
sources += [ os.path.join(libdir, x) for x in lib_srcs ]

firmwareFiles = ["coldboot.s"]
firmwareSources = [ os.path.join(firmwaredir, x) for x in firmwareFiles ]


#######################################
## Locate Toolchain Paths
#######################################
if os.name=='nt':
    pio_rel = '.apio\\packages'
    platformio_rel = '.platformio\\packages'
    #pio_rel = '.platformio\\packages\\toolchain-icestorm\\bin'
    home_path = os.getenv('HOMEPATH')

    # Build the full path to IceStorm tools
    pio = os.path.join(home_path, pio_rel)
    platformio = os.path.join(home_path, platformio_rel)

    # Tools used in the flow
    icepack       = os.path.join(pio, 'toolchain-ice40\\bin\\icepack.exe')
    icemulti      = os.path.join(pio, 'toolchain-ice40\\bin\\icemulti.exe')
    arachne_pnr   = os.path.join(pio, 'toolchain-ice40\\bin\\arachne-pnr.exe')
    nextpnr_ice40 = os.path.join(pio, 'toolchain-ice40\\bin\\nextpnr-ice40.exe')
    yosys         = os.path.join(pio, 'toolchain-yosys\\bin\\yosys.exe')
    iceprog       = os.path.join(pio, 'toolchain-ice40\\bin\\iceprog.exe')
    gcc           = os.path.join(platformio, 'toolchain-riscv\\bin\\riscv64-unknown-elf-gcc.exe')
    objcopy       = os.path.join(platformio, 'toolchain-riscv\\bin\\riscv64-unknown-elf-objcopy.exe')
    size          = os.path.join(platformio, 'toolchain-riscv\\bin\\riscv64-unknown-elf-size.exe')
    verilator     = os.path.join(pio, 'toolchain-verilator\\bin\\verilator.exe')
    
else:
    pio_rel = '.platformio/packages/'
    pio = os.path.join(os.environ['HOME'], pio_rel)
    
    # Use PlatformIO, if it exists.
    if os.path.exists(pio):
        icepack       = os.path.join(pio, 'toolchain-icestorm/bin/icepack')
        icemulti      = os.path.join(pio, 'toolchain-icestorm/bin/icemulti')
        arachne_pnr   = os.path.join(pio, 'toolchain-icestorm/bin/arachne-pnr')
        nextpnr_ice40 = os.path.join(pio, 'toolchain-icestorm/bin/nextpnr-ice40')
        yosys         = os.path.join(pio, 'toolchain-yosys/bin/yosys')
        iceprog       = os.path.join(pio, 'toolchain-icestorm/bin/iceprog')
        gcc           = os.path.join(pio, 'toolchain-riscv/bin/riscv64-unknown-elf-gcc')
        objcopy       = os.path.join(pio, 'toolchain-riscv/bin/riscv64-unknown-elf-objcopy')
        size          = os.path.join(pio, 'toolchain-riscv/bin/riscv64-unknown-elf-size')
        verilator     = os.path.join(pio, 'toolchain-verilator/bin/verilator.exe')
    # Otherwise, assume the tools are in the PATH.
    else:
        icepack       = 'icepack'
        icemulti      = 'icemulti'
        arachne_pnr   = 'arachne-pnr'
        nextpnr_ice40 = 'nextpnr-ice40'
        yosys         = 'yosys'
        iceprog       = 'iceprog'
        gcc           = 'riscv64-unknown-elf-gcc'
        objcopy       = 'riscv64-unknown-elf-objcopy'
        size          = 'riscv64-unknown-elf-size'
        verilaotor    = 'verilator'

def hexdump(infile, outfile):
    with open(outfile, 'w') as hexfile:
        with open(infile, 'rb') as binfile:
            while(1):
                word = binfile.read(4)
                if (len(word) < 4):
                    break
                hexfile.write('%02X%02X%02X%02X\n' % (word[3], word[2], word[1], word[0]))
        

#######################################
## Checks if rebuild needed
#######################################
def check_rebuild(*args, name='top', pcf='top.pcf'):
    """Checks if the FPGA bitstream needs to be rebuilt.

    Args:
       name (string): Name of the top module for verilog synthesis (default: "top")
       pcf (string): Filename of the PCF pin definitions file (default: "top.pcf")
       *args (string): All other non-kwargs should provide the verilog files to be synthesized.
    """
    bitfile = name+'.bin'
    
    if not os.path.exists(bitfile):
        return True

    bit_mtime = os.path.getmtime(bitfile)
    if os.path.getmtime(pcf) > bit_mtime:
        return True
    for x in args:
        if os.path.getmtime(os.path.join(srcdir, x)) > bit_mtime:
            return True

    return False



#######################################
## Build an FPGA Bitstream
#######################################
def build(*args, name='top', pcf='top.pcf', device='--up5k', package='sg48'):
    """Build an FPGA Bitstream for an iCE40 FPGA.

    Args:
       name (string): Name of the top module for verilog synthesis (default: "top")
       pcf (string): Filename of the PCF pin definitions file (default: "top.pcf")
       device (string): nextpnr argument to select the FPGA family (defualt: "--up5k")
       package (string): Package type of the FPGA (default: "sg48")
       *args (string): All other non-kwargs should provide the verilog files to be synthesized.
    """
    synth_cmd = 'synth_ice40 -abc2 -top ' + name + ' -json ' + name + '.json'
    if call([yosys, '-q', '-p', synth_cmd] + [os.path.join(srcdir, x) for x in args] ) != 0:
        return
    if call([nextpnr_ice40, device, '--package', package, '--opt-timing', '--pcf', pcf, '--json', name+'.json', '--asc', name+'.asc']) != 0:
        return
    if call([icepack, '-s', name+'.asc', name+'.bin']) != 0:
        return

#######################################
## Check if recompile needed
#######################################
def check_rebuild_rom(*args, name='firmware'):
    """Checks if the firmware needs to be rebuilt.

    Args:
       name (string): Name of the firmware image (default: "firmware.mem")
       *args (string): All other non-kwargs should provide the source files for the firmware.
    """
    firmwareImage = os.path.join(srcdir, name + '.mem')

    if not os.path.exists(firmwareImage):
        return True

    firmwareTime = os.path.getmtime(firmwareImage)
    for x in args:
        if os.path.getmtime(os.path.join(srcdir, x)) > firmwareTime:
            return True

    return False
    
#######################################
## Recompile firmware
#######################################
def build_rom(*args, name='firmware'):
    """Rebuilds the firmware.

    Args:
       name (string): Name of the firmware image (default: "firmware")
       *args (string): All other non-kwargs should provide the source files for the firmware.
    """
    print("Rebuilding Firmware:")

    objfiles = []
    
    for x in args:
        infile = os.path.join(firmwaredir, x)
        outfile = os.path.splitext(infile)[0] + '.o'
        objfiles += [outfile]
        
        print("   Compiling  [" + infile + "]")
        if call([gcc] + CFLAGS + ['-c', '-o', outfile, infile]) != 0:
            print("---- Error compiling ----")
            return

    #$(CROSS_COMPILE)gcc $(LDFLAGS) -o $@ $^
    elffile = os.path.join(firmwaredir, name + '.elf')
    print("   Linking    [" + elffile + "]")
    if call([gcc] + LDFLAGS + ['-o', elffile] + objfiles) != 0:
        print("---- Error compiling ----")
        return

    #%.bin: %.elf
    #   $(CROSS_COMPILE)objcopy -O binary $^ $@
    binfile = os.path.join(firmwaredir, name + '.bin')
    print("   Generating [" + binfile + "]")
    if call([objcopy, '-O', 'binary', elffile, binfile]) != 0:
        return

    memfile = os.path.join(srcdir, name + '.mem')
    hexdump(binfile, memfile)

    print("Firmware Memory Usage:")
    call([size, '-t', elffile], stderr=subprocess.STDOUT)


#######################################
## Simulate target
#######################################
def simulate(*args, name='top', tempdir='./sim'):
    #$(SIMTOP): $(SIMTOP).v $(SOURCES) $(SIMTOP).cpp firmware.mem
    #   verilator --trace --top-module $(SIMTOP) -cc $(filter %.v,$^) -Wno-fatal --exe $(SIMTOP).cpp
    #   make -C obj_dir -f V$(SIMTOP).mk
    try:
        os.makedirs(tempdir)
    except FileExistsError as e:
        pass

    if call([verilator, '--trace', '--top-module', name, '-cc'] + [*args] + ['Wno-fatal', '--exe', os.path.join(tempdir, name+'.cpp')]) != 0:
        return

    
        
    
#######################################
## Cleanup After Ourselves
#######################################
def clean():
    del_files = glob('*.bin')+glob('*.blif')+glob('*.rpt')+glob('*.asc') + glob('*.json')
    del_files += glob(os.path.join(firmwaredir, '*.o'))
    del_files += glob('*.mem') + glob('*.elf')
    for del_file in del_files:
        os.remove(del_file)

#######################################
## Generate Memory Blocks
#######################################
def generate():
    call(["python3", "generate_luts.py"])

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('command', metavar='COMMAND', nargs='*', default=['auto'],
                        help="Make target to run, one of build|clean|generate|bootloader|multiboot|upload|iceprog")
    args = parser.parse_args()

    # Name of the Verilog source file *without* the ".v" extension
    name = 'top'

    if args.command[0] == 'auto':
        newstuff = []

        # check firstboot
        if (check_rebuild('bootloader/firstboot.v', name='firstboot', pcf=pcf_file) or
            check_rebuild(*boot_srcs, name='tinydfu', pcf=pcf_file)):
            newstuff += ['bootloader']

            
        if check_rebuild_rom(*firmwareSources):
            newstuff += ['buildrom']
            
        # check main build
        if check_rebuild(*sources, name='top', pcf=pcf_file):
            newstuff += ['build']
        elif 'buildrom' in newstuff:
            newstuff += ['build']
            
            
        if len(newstuff) > 0:
            newstuff += ['multiboot']

        # get rid of the auto
        args.command = newstuff + args.command[1:]

        
    for command in args.command:
        # run command
        if command == 'build':
            generate()
            build(*sources, name='top', pcf=pcf_file)

        elif command == 'buildrom':
            build_rom(*firmwareSources)
            
        elif command == 'generate':
            generate()

        elif command == 'bootloader' or command == "booploader":
            build('bootloader/firstboot.v', name='firstboot', pcf=pcf_file)
            build(*boot_srcs, name='tinydfu', pcf=pcf_file)
        
        elif command == 'multiboot':
            if call([icemulti, '-v', '-o', 'multiboot.bin', '-a15', 'firstboot.bin', 'tinydfu.bin', 'top.bin']) != 0:
                return

        elif command == 'upload':
            if call(['dfu-util', '-e', '-a0', '-D', name+'.bin', '-R']) != 0:
                return
        
        elif command == 'iceprog':
            if call([iceprog, 'multiboot.bin']) != 0:
                return
        
        elif command == 'iceread':
            if call([iceprog, '-R', "1M", 'readout.bin']) != 0:
                return

        elif command == 'simulate':
            simulate(*sources, name='top', tempdir='./sim')
            
        elif command == 'clean':
            clean()
            
        else:
            raise Exception('Invalid command', command)

if __name__=='__main__':
    main()
