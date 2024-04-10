#setup system time
ln -sf /sur/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service
systemctl enable sddm.service

locale-gen
echo 'LANG=en_GB.UTF-8' >/etc/locale.conf
read -p "Enter hostname: " hn
echo $hn >/etc/hostname

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
visudo
read -p "Enter new password: " pass1 </dev/tty
read -p "Enter new password again: " pass2 </dev/tty
if $pass1 == $pass2; then
	passwd sam $pass1
	echo "password was modified"
else
	echo "passwords were not equal"
fi
