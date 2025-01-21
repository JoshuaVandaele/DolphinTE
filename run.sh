. Scripts/dependencies.sh

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
