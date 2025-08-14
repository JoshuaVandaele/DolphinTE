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

2. Launch `setup.sh` to automatically create the test environment.

3. Once setup has completed, launch `run.sh` to run the virtual machine.

4. You can then SSH into it using `ssh.sh`.

5. If you want to add a remote repository, use `add-remote.sh` with the remote name and URL as arguments.

6. If you want to build Dolphin, you can use `build.sh` with the remote name and branch as arguments.

You may use the `--gui` flag to be able to interact with the virtual machine through a GUI.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.
