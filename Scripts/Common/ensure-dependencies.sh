QEMU_NAME=qemu-system-x86_64
QEMU=$(command -v $QEMU_NAME)

if [ ! -x $QEMU ]; then
    for dir in "/usr/local/bin" "/usr/bin" "/opt/qemu" "/usr/local/sbin"; do
        if [ -x "$dir/$QEMU_NAME" ]; then
            $QEMU="$dir/$QEMU_NAME"
            break
        fi
    done
fi

if [ ! -x $QEMU ]; then
    echo "qemu-system-x86_64 not found"
    exit 1
fi
export QEMU

FIRMWARE=/usr/share/edk2/x64/OVMF_CODE.4m.fd
if [ ! -r "$FIRMWARE" ]; then
    echo "Missing file: $(realpath -s $FIRMWARE)"
    echo "(Is OVMF installed?)"
    exit 1
fi
export FIRMWARE

VARIABLE_STORE_RO=/usr/share/edk2/x64/OVMF_VARS.4m.fd
if [ ! -r "$VARIABLE_STORE_RO" ]; then
    echo "Missing file: $(realpath -s $VARIABLE_STORE_RO)"
    echo "(Is OVMF installed?)"
    exit 1
fi
export VARIABLE_STORE_RO
