SETUP_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))"
. $SETUP_DIR/../Constants/windows.sh

PATCHED_ISO_PATH="$(dirname "$ISO_PATH")/unattend-$(basename "$ISO_PATH")"

TEMP_ISO_DIR=$(mktemp -d)
ISO_FILE_SIZE=$(stat -c%s "$ISO_PATH")

AVAILABLE_SPACE=$(df --output=avail -B1 "$TEMP_ISO_DIR" | tail -n 1)
if [ "$AVAILABLE_SPACE" -lt "$ISO_FILE_SIZE" ]; then
    echo "Not enough space in temporary directory $TEMP_ISO_DIR.">&2
    echo "need $ISO_FILE_SIZE bytes" >&2
    echo "have $AVAILABLE_SPACE bytes.">&2
    exit 1
fi

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
