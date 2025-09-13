RUN_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))"
. $RUN_DIR/../Constants/windows.sh

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
    $GUI_OPTION
