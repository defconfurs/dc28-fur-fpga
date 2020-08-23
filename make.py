#!/usr/bin/python3
import os
import sys
import argparse
from subprocess import call
from glob import glob

srcdir = os.path.dirname(os.path.abspath(__file__))

#######################################
## FPGA Source Files
#######################################
pcf_file = "Prototype2_hardware.pcf"

# Common USB sources, shared by both the DFU bootloader and user bitstream.
rtl_usb_dir = 'tinydfu-bootloader/usb'
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
stub_usb_srcs += ["usb_dfu_stub.v",
                  "usb_dfu_stub_ep.v"]

sources = glob(os.path.join(srcdir, '*.v'))
sources += [ os.path.join(rtl_usb_dir, x) for x in stub_usb_srcs ]

#######################################
## Locate Toolchain Paths
#######################################
if os.name=='nt':
    pio_rel = '.apio\\packages'
    #pio_rel = '.platformio\\packages\\toolchain-icestorm\\bin'
    home_path = os.getenv('HOMEPATH')

    # Build the full path to IceStorm tools
    pio = os.path.join(home_path, pio_rel)

    # Tools used in the flow
    icepack       = os.path.join(pio, 'toolchain-ice40\\bin\\icepack.exe')
    icemulti      = os.path.join(pio, 'toolchain-ice40\\bin\\icemulti.exe')
    arachne_pnr   = os.path.join(pio, 'toolchain-ice40\\bin\\arachne-pnr.exe')
    nextpnr_ice40 = os.path.join(pio, 'toolchain-ice40\\bin\\nextpnr-ice40.exe')
    yosys         = os.path.join(pio, 'toolchain-yosys\\bin\\yosys.exe')
    iceprog       = os.path.join(pio, 'toolchain-ice40\\bin\\iceprog.exe')

else:
    pio_rel = '.platformio/packages/toolchain-icestorm/bin'
    pio = os.path.join(os.environ['HOME'], pio_rel)
    
    # Use PlatformIO, if it exists.
    if os.path.exists(pio):
        icepack       = os.path.join(pio, 'icepack')
        icemulti      = os.path.join(pio, 'icemulti')
        arachne_pnr   = os.path.join(pio, 'arachne-pnr')
        nextpnr_ice40 = os.path.join(pio, 'nextpnr-ice40')
        yosys         = os.path.join(pio, 'yosys')
        iceprog       = os.path.join(pio, 'iceprog')
    # Otherwise, assume the tools are in the PATH.
    else:
        icepack       = 'icepack'
        icemulti      = 'icemulti'
        arachne_pnr   = 'arachne-pnr'
        nextpnr_ice40 = 'nextpnr-ice40'
        yosys         = 'yosys'
        iceprog       = 'iceprog'


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
    synth_cmd = 'synth_ice40 -top ' + name + ' -json ' + name + '.json'
    if call([yosys, '-q', '-p', synth_cmd] + [os.path.join(srcdir, x) for x in args] ) != 0:
        return
    if call([nextpnr_ice40, device, '--package', package, '--opt-timing', '--pcf', pcf, '--json', name+'.json', '--asc', name+'.asc']) != 0:
        return
    if call([icepack, name+'.asc', name+'.bin']) != 0:
        return

#######################################
## Checks if rebuild needed
#######################################
def check_rebuild(*args, name='top', pcf='top.pcf'):
    """Build an FPGA Bitstream for an iCE40 FPGA.

    Args:
       name (string): Name of the top module for verilog synthesis (default: "top")
       pcf (string): Filename of the PCF pin definitions file (default: "top.pcf")
       device (string): nextpnr argument to select the FPGA family (defualt: "--up5k")
       package (string): Package type of the FPGA (default: "sg48")
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
## Cleanup After Ourselves
#######################################
def clean():
    del_files = glob('*.bin')+glob('*.blif')+glob('*.rpt')+glob('*.asc') + glob('*.json')
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
            
        # check main build
        if check_rebuild(*sources, name='top', pcf=pcf_file):
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

        elif command == 'clean':
            clean()
            
        else:
            raise Exception('Invalid command', command)

if __name__=='__main__':
    main()
