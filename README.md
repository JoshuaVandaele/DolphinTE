# DolphinTE

DolphinTE (or Dolphin Test Environment) is a personal project used to test my changes to [Dolphin](https://github.com/dolphin-emu) inside virtual machines.

## Requirements

- QEMU
- edk2's OVMF
- cdrtools
- p7zip
- ISO file of supported operating system

### Usually installed requirements

- bash
- util-linux
- GNU coreutils
- SSH client

## Usage

1. Put your isos inside `Data/ISO`.

2. Run `dolphinte.sh --setup <OSes>` to create and set up new virtual machine(s).

3. Run `dolphinte.sh <OSes>` to start the virtual machine(s).

4. You can then SSH into them using `ssh.sh`.

5. If you want to add a remote repository in the running VMs, use `add-remote.sh <Remote> <URL>`.

6. If you want to build Dolphin in the running VMs, you can use `build.sh <Remote> <URL>`.

You may use the `--nogui` flag to run QEMU without a graphical interface.

## Supported Operating Systems

- Windows 11

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more information.
