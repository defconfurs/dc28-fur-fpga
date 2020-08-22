# Cross-platform iCEstick build script

# Steven Herbst <sgherbst@gmail.com>
# Updated: February 28, 2017

# `python make.py build` will build 
# `python make.py upload` will upload the generated bitstream to the FPGA
# `python make.py clean` will remove generated binaries

# Inspired by CS448H, Winter 2017
# https://github.com/rdaly525/CS448H

import os
import sys
import argparse
from subprocess import call
from glob import glob

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('command', nargs='*', default=['build'], help='build|upload|clean')
    args = parser.parse_args()

    # Implement case insensitive commands
    commands = args.command

    # Name of the Verilog source file *without* the ".v" extension
    name = 'top'

    pcf_file = "Prototype2_hardware.pcf"
    
    # Platform-specific path to IceStorm tools
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
        tinyprog      = 'tinyprog'

    else:
        pio_rel = '.platformio/packages/toolchain-icestorm/bin'
        home_path = os.environ['HOME']
        file_ext = ''
    
        # Build the full path to IceStorm tools
        pio = os.path.join(home_path, pio_rel)
        
        # Tools used in the flow
        icepack       = os.path.join(pio, 'icepack'+file_ext)
        icemulti      = os.path.join(pio, 'icemulti'+file_ext)
        arachne_pnr   = os.path.join(pio, 'arachne-pnr'+file_ext)
        nextpnr_ice40 = os.path.join(pio, 'nextpnr-ice40'+file_ext)
        yosys         = os.path.join(pio, 'yosys'+file_ext)
        iceprog       = os.path.join(pio, 'iceprog'+file_ext)
        tinyprog      = 'tinyprog'

    sources = glob('*.v')
    sources += ["usb/edge_detect.v",
                "usb/strobe.v",
                "usb/usb_fs_in_arb.v",
                "usb/usb_fs_in_pe.v",
                "usb/usb_fs_out_arb.v",
                "usb/usb_fs_out_pe.v",
                "usb/usb_fs_pe.v",
                "usb/usb_fs_rx.v",
                "usb/usb_fs_tx_mux.v",
                "usb/usb_fs_tx.v",
                "usb/usb_dfu_app_ep.v",
                "usb/usb_dfu_core.v",
                "usb/usb_phy_ice40.v"]

    for command in commands:
        # run command
        if command == 'build':
            synth_cmd = 'synth_ice40 -top top -json ' + name + '.json'
            if call([yosys, '-q', '-p', synth_cmd] + sources) != 0:
                return
            if call([nextpnr_ice40, '--up5k', '--package', 'sg48', '--opt-timing', '--pcf', pcf_file, '--json', name+'.json', '--asc', name+'.asc']) != 0:
                return
            if call([icepack, name+'.asc', 'top.bin']) != 0:
                return

            # make multiboot.bin
            #if call([icemulti, "-v", "-o", "multiboot.bin", "-p0", "-A15", 'firstboot.bin', 'bootloader/tinydfu.bin', 'top.bin']) != 0:
            #    return


            
        elif command == 'upload':
            if call(['dfu-util', '-a2', '-D', name+'.bin', '-R']) != 0:
                return
        
        elif command == 'iceprog':
            if call([iceprog, 'top.bin']) != 0:
                return
        
        elif command == 'iceread':
            if call([iceprog, '-R', "1M", name+'.bin_readout']) != 0:
                return
        
        elif command == 'iceproghelp':
            if call([iceprog, '-p', name+'.bin', '-IA', '--help']) != 0:
                return
        
        elif command == 'clean':
            del_files = glob('*.bin')+glob('*.blif')+glob('*.rpt')+glob('*.asc') + [name+'.json']
            for del_file in del_files:
                os.remove(del_file)
            
        else:
            raise Exception('Invalid command')

if __name__=='__main__':
    main()
