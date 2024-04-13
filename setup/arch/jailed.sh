#setup system time
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service
systemctl enable sddm.service

sed 's/#en_(US|GB).UTF-8/en_$1.UTF-8 UTF-8/' -i /etc/locale.gen
locale-gen
echo 'LANG=en_GB.UTF-8' >/etc/locale.conf
timedatectl set-timezone Europe/Amsterdam
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

passwd sam

bootctl list
