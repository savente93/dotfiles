#setup system time
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service
systemctl enable sddm.service
systemctl enable NetworkManager

sed 's/#en_GB.UTF-8.*/en_GB.UTF-8 UTF-8/g;s/#en_US.UTF-8.*/en_US.UTF-8 UTF-8/g' -i /etc/locale.gen
locale-gen
echo 'LANG=en_GB.UTF-8' >/etc/locale.conf
timedatectl set-timezone Europe/Amsterdam
read -r -p "Enter hostname: " hn
echo "$hn" >/etc/hostname

#setup bootloader
bootctl install
echo 'default  arch.conf
timeout  1
console-mode max
editor   no' >/boot/loader/loader.conf

echo "title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p3) rw" >/boot/loader/entries/arch.conf

useradd -m -G wheel sam

# arch wiki would be very mad at me but whatever it's my system I can do what I want
# This is roughly what visudo does but I don't want to type
# so I'll do it myself so I can do this step unattended.
sudo cp /etc/sudoers sudoers.tmp
echo 'Defaults passwd_timeout=0' | sudo tee -a sudoers.tmp
echo '%wheel ALL = (ALL:ALL) ALL' | sudo tee -a sudoers.tmp
if visudo -c sudoers.tmp; then
	sudo mv sudoers.tmp /etc/sudoers
else
	echo "Error in sudoers.tmp! aborting..."
	exit 1
fi

passwd sam
mkdir -p /home/sam/.config/sway
cp /etc/sway/config /home/sam/.config/sway
chown -R sam /home/sam/.config

curl https://raw.githubusercontent.com/savente93/dotfiles/main/setup/setup.sh -o /home/sam/setup.sh
chmod +x /home/sam/setup.sh
chown sam /home/sam/setup.sh

bootctl list
