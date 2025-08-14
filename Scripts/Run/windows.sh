. ../Constants/windows.sh

USB_ARGS=$(../Common/usbparse.sh ../../usb_devices.conf)

$QEMU \
    -enable-kvm \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -drive file="$VM_DISK_PATH",format=qcow2,media=disk \
    -boot c \
    -cpu host \
    -usb -device usb-mouse \
    -device usb-kbd \
    -drive if=pflash,format=raw,readonly=on,file=$FIRMWARE \
    -drive if=pflash,format=raw,file=$VARIABLE_STORE \
    -nic user,hostfwd=tcp::10022-:10022 \
    $USB_ARGS \
    $GUI_OPTION
