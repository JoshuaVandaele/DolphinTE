. Scripts/Common/ensure-dependencies.sh
source Scripts/Common/argparse.sh

USB_ARGS=$(Scripts/Common/usbparse.sh usb_devices.conf)
QEMU="$QEMU $USB_ARGS"

cd Scripts/Run
for file in "../Constants/*"; do
    . $file
    if [ ! -r "$VM_DISK_PATH" ]; then
        echo "Missing file: $(realpath -s $VM_DISK_PATH)"
        echo "(Has the virtual machine been setup first?)"
        exit 1
    fi
done

./windows.sh
