function os_installed() {
    local file="$1"
    local min_size="${2:-104857600}"  # Default 100MB in bytes

    if [[ -f "$file" ]]; then
        if (( min_size > 0 )); then

            local filesize
            filesize=$(stat -c%s "$file")
            if (( filesize >= min_size )); then
                echo "true"
                return
            fi
        fi
    fi
    echo "false"
}



function print_help() {
    echo "Usage: $0 [OPTIONS] <Operating Systems | all>"
    echo
    echo "Options:"
    echo "  --nogui             Run without GUI (no display, serial output only)"
    echo "  --setup             Setup the virtual machine (default is to run the VM)"
    echo "  --list              List supported operating systems"
    echo "  -h, --help          Show this help message and exit"
}

function list_supported_os() {
    . Scripts/Constants/windows.sh
    local is_windows_installed=$(os_installed "$VM_DISK_PATH")

    echo "Supported Operating Systems:"
    echo "- Windows 11 $( [[ $is_windows_installed == "true" ]] && echo '(installed)' || echo '(not installed)' )"
    echo "  aliases: win, win11, windows, windows11"
    # echo "- Ubuntu 24.04 LTS $( [[ $is_ubuntu_installed == "true" ]] && echo '(installed)' || echo '(not installed)' )"
    # echo "  aliases: ubuntu, ubuntu24, ubuntu2404, ubuntu lts, ubuntults"
}

function parse_os() {
    local input="${1,,}"
    case "$input" in
        "windows 11" | win | win11 | windows | windows11)
            echo "windows"
            ;;
        # "ubuntu 24.04 lts" | "ubuntu lts" | ubuntu | ubuntu24 | ubuntu2404 | ubuntults)
        #     echo "ubuntu"
        #     ;;
        *)
            echo "Unsupported operating system: $input" >&2
            exit 1
            ;;
    esac
}

function parse_oses() {
    local os_list=()
    for os in "$@"; do
        if [[ "${os,,}" == "all" ]]; then
            os_list+=("windows")
            # os_list+=("ubuntu")
            break
        else
            os_list+=("$(parse_os "$os")") || exit 1
        fi
    done
    # Remove duplicates
    echo "$(echo "${os_list[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
}

ARGS=$(getopt -o h --long help,nogui,setup,list -n "$0" -- "$@")

eval set -- "$ARGS"

NOGUI=false
SETUP=false

while true; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        --list)
            list_supported_os
            exit 0
            ;;
        --nogui)
            NOGUI=true
            shift
            ;;
        --setup)
            SETUP="true"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$1" ]]; then
    echo "No operating system specified. Use --list to see supported operating systems." >&2
    exit 1
fi
OSES=$(parse_oses "$@")

if [[ $NOGUI == "true" ]]; then
    GUI_OPTION="-nographic \
    -serial none \
    -monitor none"
else
    GUI_OPTION="-display sdl \
    -audiodev pipewire,id=audiodev1 \
    -device intel-hda \
    -device hda-duplex,audiodev=audiodev1"
fi

export OSES
export GUI_OPTION
export SETUP