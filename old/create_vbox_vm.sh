#!/usr/bin/env bash

# get path to macOS image
if [ -e "$1" ]; then
  OS_IMAGE="$1"
else
  echo >&2 "Usage: Please specify filepath to macOS image as a parameter to this script."
  exit 1
fi

# make sure VirtualBox is installed
command -v VBoxManage >/dev/null 2>&1 || {
  cat >&2 <<-EOF
    Please install VirtualBox 5.1.8 or higher in order to proceed.

    VirtualBox can be installed via Homebrew Cask:

    -- Install Homebrew:
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    -- Install Cask:
    brew tap caskroom/cask

    -- Install VirtualBox cask:
    brew cask install virtualbox
EOF
  exit 1
}

# get system info
CPU_CORES="$(sysctl hw.ncpu | awk '{print $2}')"
RAM_GB="$(sysctl hw.memsize | awk '{print $2 / 1024 / 1024 / 1024}')"
RECOMMENDED_RAM_GB="$((RAM_GB / 2))"

# ask for VM name
while [ -z "$VM_NAME" ]
do
  printf "Please choose a descriptive name for the virtual machine: "
  read -r VM_NAME
done

# ask for # of CPU cores
while [[ "$VM_CPUS" -gt "$CPU_CORES" || "$VM_CPUS" -lt 1 || ! "$VM_CPUS" =~ ^[0-9]+$ ]]
do
  printf "Please choose # of CPU cores for the virtual machine. At least 2 is recommended: "
  read -r VM_CPUS
done

# ask for RAM amount
while [[ "$VM_RAM_GB" -gt "$RAM_GB" || "$VM_RAM_GB" -lt 1 || ! "$VM_RAM_GB" =~ ^[0-9]+$ ]]
do
  printf "Please choose amount of RAM (in GB). %s GB is recommended: " "$RECOMMENDED_RAM_GB"
  read -r VM_RAM_GB
done

# ask for storage disk space
while [[ "$VM_STORAGE" -gt 100 || "$VM_STORAGE" -lt 10 || ! "$VM_STORAGE" =~ ^[0-9]+$ ]]
do
  printf "Please choose size (in GB) for virtual machine disk. 10GB minimum; 20 GB is recommended: "
  read -r VM_STORAGE
done

echo "Creating a virtual machine with $VM_CPUS CPU cores, $VM_RAM_GB GB of RAM, and $VM_STORAGE GB of disk space..."

# installation path
MACHINE_FOLDER="$HOME/VirtualBox VMs/$VM_NAME"

# create VM
VBoxManage createvm --name "$VM_NAME" --ostype "MacOS_64" --register

# modify VM settings
VBoxManage modifyvm "$VM_NAME" --cpus "$VM_CPUS" --memory "$((VM_RAM_GB * 1024))" \
  --cpuidset 00000001 000306a9 00020800 80000201 178bfbff --chipset piix3 \
  --boot1 dvd --boot2 disk --firmware efi --vram 128 \
  --mouse usbtablet --keyboard usb --audio none --clipboard bidirectional

VBoxManage createhd --filename "$MACHINE_FOLDER/$VM_NAME.vmdk" --size "$((VM_STORAGE * 1000))" --format VMDK --variant Fixed

VBoxManage storagectl "$VM_NAME" --name SATA --add sata --controller IntelAhci --portcount 2 --bootable on

VBoxManage storageattach "$VM_NAME" --storagectl SATA --port 0 --type hdd --medium "$MACHINE_FOLDER/$VM_NAME.vmdk"

VBoxManage storageattach "$VM_NAME" --storagectl SATA --port 1 --type dvddrive --medium "$OS_IMAGE"

# display macOS installation steps
cat "$(dirname "$0")/installation_steps.txt"

# launch VM
VBoxManage startvm "$VM_NAME" --type gui
