#!/bin/bash

OSES=("windows")
OS_PORT_MAP=(10022)
TEMP_FOLDER="/tmp/dolphinte"
RUNNING_OSES=()
PIDS=()

for OS in "${OSES[@]}"; do
    if [ -f "$TEMP_FOLDER/$OS.lock" ]; then
        RUNNING_OSES+=("$OS")
    fi
done

if [ ${#RUNNING_OSES[@]} -eq 0 ]; then
    echo "No running virtual machines found. Start one with dolphinte.sh first."
    exit 1
fi

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
trap cleanup EXIT SIGINT SIGTERM

ssh_to_vm() {
    local OS="$1"
    shift

    local PORT=""
    for i in "${!OSES[@]}"; do
        if [ "${OSES[$i]}" = "$OS" ]; then
            PORT="${OS_PORT_MAP[$i]}"
            break
        fi
    done

    local LOG_FILE="$TEMP_FOLDER/$OS-ssh.log"

    # Base SSH options
    local SSH_OPTS=(-i Data/unsecurekey_rsa
                    -o UserKnownHostsFile=/dev/null
                    -o StrictHostKeyChecking=no
                    -o PasswordAuthentication=no
                    -o ConnectTimeout=2
                    -p "$PORT"
                    runner@localhost)

    while true; do
        if [ $# -gt 0 ]; then
            if printf "%s\n" "$@" | ssh "${SSH_OPTS[@]}" -T &>>$LOG_FILE; then
                break
            fi
        else
            # Drop an interactive shell if no arguments are provided
            if ssh "${SSH_OPTS[@]}" 2>&1 | tee -a $LOG_FILE; then
                break
            fi
        fi
        echo "Waiting for SSH to become available..."
        sleep 2
    done
}


for OS in "${RUNNING_OSES[@]}"; do
    if [ ${#@} -eq 0 ]; then
        ssh_to_vm "$OS"
    else
        ssh_to_vm "$OS" "$@" &
        PIDS+=($!)
    fi
done

for pid in "${PIDS[@]}"; do
    wait "$pid"
done