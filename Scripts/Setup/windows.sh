#!/bin/bash

. ../Constants/windows.sh

PATCHED_ISO_PATH="$(dirname "$ISO_PATH")/unattend-$(basename "$ISO_PATH")"

TEMP_ISO_DIR=$(mktemp -d)

7z x -y "$ISO_PATH" -o"$TEMP_ISO_DIR"
cp -fr "$ANSWER/." "$TEMP_ISO_DIR"

rm -f $PATCHED_ISO_PATH

mkisofs -o "$PATCHED_ISO_PATH" \
    -b "boot/etfsboot.com" -no-emul-boot -iso-level 4 \
    -JlDN -joliet-long -relaxed-filenames -V "Windows" -udf \
    -boot-info-table -eltorito-alt-boot -eltorito-boot "efi/microsoft/boot/efisys_noprompt.bin" -no-emul-boot \
    "$TEMP_ISO_DIR"

rm -rf "$TEMP_ISO_DIR"

if [ ! -r $PATCHED_ISO_PATH ]; then
    echo "Failed to create patched ISO image"
    exit 1
fi

echo "Creating virtual disk image..."
qemu-img create -f qcow2 $VM_DISK_PATH $DISK_SIZE

echo "Creating variable store..."
cp $VARIABLE_STORE_RO $VARIABLE_STORE

echo "Starting QEMU with Windows ISO..."

$QEMU \
    -enable-kvm \
    -m "$MEMORY" \
    -nic user \
    -smp "$CPUS" \
    -cdrom "$PATCHED_ISO_PATH" \
    -drive file="$VM_DISK_PATH",format=qcow2,media=disk \
    -boot d \
    -cpu host \
    -usb -device usb-mouse \
    -device usb-kbd \
    -drive if=pflash,format=raw,readonly=on,file=$FIRMWARE \
    -drive if=pflash,format=raw,file=$VARIABLE_STORE \
    $GUI_OPTION

if [ $? -eq 0 ]; then
    echo "Windows VM set up"
else
    echo "An error occured while setting up the Windows VM!"
fi
