. Scripts/Common/dependencies.sh
source Scripts/Common/argparse.sh

cd Scripts/Setup
for file in "../Constants/*"; do
    . $file
    if [ ! -r "$ISO_PATH" ]; then
        echo "Missing file: $(realpath -s $ISO_PATH)"
        exit 1
    fi
done

./windows.sh
