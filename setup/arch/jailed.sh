#setup system time
ln -sf /sur/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service

locale-gen
echo 'LANG=en_us.UTF-8' >/etc/locale.conf
read -p "Enter hostname: " hn
echo $hn >/etc/hostname

#setup bootloader
bootctl install
echo 'default  arch.conf
timeout  4
console-mode max
editor   no' >/boot/loader/loader.conf

echo "title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(lsblk -dno UUID /dev/nvme0n1p3) rw" >/boot/loader/entries/arch.conf
