#!/usr/bin/env bash
. Scripts/Common/ensure-dependencies.sh
source Scripts/Common/argparse.sh

set -euo pipefail

USB_ARGS=$(Scripts/Common/usbparse.sh usb_devices.conf)
QEMU="$QEMU $USB_ARGS"
PIDS=()
LOCK_DIR="/tmp/dolphinte"
mkdir -p "$LOCK_DIR"

cleanup() {
    if [ ${#PIDS[@]} -eq 0 ]; then
        return
    fi
    local pid
    for pid in "${PIDS[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            continue
        fi
        echo "Terminating process $pid"
        kill "$pid"
    done
}

verify_os_files() {
    local missing=()
    local OS="$1"
    if [ ! -r "Scripts/Constants/$OS.sh" ]; then
        missing+=("Scripts/Constants/$OS.sh")
    fi
    if [ ! -r "$SCRIPT_DIR/$OS.sh" ]; then
        missing+=("$SCRIPT_DIR/$OS.sh")
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        return
    fi
    echo "Missing files for $OS: ${missing[*]}"
    exit 1
}

if [[ $SETUP == "true" ]]; then
    SCRIPT_DIR="Scripts/Setup"
    CHECK_VAR="ISO_PATH"
else
    SCRIPT_DIR="Scripts/Run"
    CHECK_VAR="VM_DISK_PATH"
fi

trap cleanup EXIT SIGINT SIGTERM
for OS in ${OSES[@]}; do
    verify_os_files "$OS"
    . Scripts/Constants/"$OS".sh
    VAR_VALUE="${!CHECK_VAR}"
    if [ ! -r "$VAR_VALUE" ]; then
        echo "Missing file: $(realpath -s "$VAR_VALUE")"
        echo "(Has the virtual machine been setup first?)"
        exit 1
    fi

    LOCK_FILE="$LOCK_DIR/$OS.lock"
    exec {LOCK_FD}>$LOCK_FILE
    if ! flock -n "$LOCK_FD"; then
        echo "Another instance is already running for $OS. Skipping."
        continue
    fi

    (
        flock "$LOCK_FD"
        $SCRIPT_DIR/"$OS".sh
    ) &
    PIDS+=($!)
done

for pid in "${PIDS[@]}"; do
    wait "$pid"
done