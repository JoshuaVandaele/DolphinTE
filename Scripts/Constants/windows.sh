#!/bin/bash

# Get the directory this script is in
CONSTANTS_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))"

# Last modified iso file in Data/ISO containing "windows" in its name
ISO_PATH="$(find "$CONSTANTS_DIR/../../Data/ISO" -type f -iname "*windows*.iso" ! -iname "*unattend*.iso" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)"
VM_DISK_PATH="$CONSTANTS_DIR/../../Disks/windows.img"
VARIABLE_STORE="$CONSTANTS_DIR/../../Firmware/OVMF_VARS-windows.4m.fd"
DISK_SIZE="70G"
MEMORY="4G"
CPUS="4"
ANSWER="$CONSTANTS_DIR/../../Data/Unattend"