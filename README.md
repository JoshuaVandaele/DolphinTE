# DolphinTE

DolphinTE (or Dolphin Test Environment) is a personal project used to test my changes to [Dolphin](https://github.com/dolphin-emu) inside virtual machines.

## Requirements

- QEMU
- edk2's OVMF
- cdrtools
- p7zip
- A Windows 11 ISO

## Usage

1. Put your Windows 11 iso inside `Data/ISO` under the name `windows.iso`.

1. Launch `setup.sh` to automatically create the test environment.

1. Once setup has completed, launch `run.sh` to run the virtual machine.

1. You can then SSH into it using `ssh.sh`.

You may use the `--gui` flag to be able to interact with the virtual machine through a GUI.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.
