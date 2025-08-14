#!/bin/bash
# Usage: ./parse-usb-devices.sh <usb_devices_file>
# Outputs: -device usb-host,vendorid=...,productid=...

USB_DEVICES_FILE="$1"

if [ -z "$USB_DEVICES_FILE" ]; then
    echo "Usage: $0 <usb_devices_file>" >&2
    exit 1
fi

if [ ! -f "$USB_DEVICES_FILE" ]; then
    echo "Error: File '$USB_DEVICES_FILE' not found." >&2
    exit 1
fi

USB_ARGS=""
while IFS=: read -r VID PID; do
    # Skip empty lines or lines starting with '#'
    [[ -z "$VID" || "$VID" =~ ^# ]] && continue
    USB_ARGS="$USB_ARGS -device usb-host,vendorid=$VID,productid=$PID"
done < "$USB_DEVICES_FILE"

echo "$USB_ARGS"
