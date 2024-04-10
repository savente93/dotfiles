timedatectl

# Format disk

# Calculate swap size
ram=$(free -b | awk '/^Mem:/{print $2}')
swap_size=$((ram + ram / 5)) # 20% more than RAM

# Create partition table
echo "label: gpt" | sfdisk /dev/nvme0n1

# Create EFI boot partition (1 GB)
echo ",+1G,U" | sfdisk /dev/nvme0n1

# Create swap partition
echo ",+${swap_size},S" | sfdisk --append /dev/nvme0n1

# Create EXT4 partition (rest of the drive)
echo ",," | sfdisk --append /dev/nvme0n1

# Format partitions
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2

#insalling packages
#update mirror list
reflector

#install what we'll need for system setup after reboot
pacstrap -K /mnt amd-ucode base curl devel-base firefox fsck git i3-wm linux linux-firmware man-db man-pages networkmanager nvidia nvidia-utils openssl sddm sof-firmware sshd sudo texinfo vim xorg-server

genfstab -U /mnt >>/mnt/etc/fstab

# stuff we have to do in jail
curl https://raw.githubusercontent.com/savente93/dotfiles/main/setup/arch/jailed.sh -o /mnt/jailed.sh
chmod +x /mnt/jailed.sh
arch-chroot /mnt /bin/bash /jailed.sh
rm /mnt/jailed.sh

