#!/bin/bash

# MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer

function main()
{
	resourcesPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	log="${resourcesPath}/log.txt"

	hostname=$(getSetting "hostname") || { failMessage "Retrieving setting 'hostname'"; return 1; }
	rootpassword=$(getSetting "rootpassword") || { failMessage "Retrieving setting 'rootpassword'"; return 1; }
	username=$(getSetting "username") || { failMessage "Retrieving setting 'username'"; return 1; }
	userpassword=$(getSetting "userpassword") || { failMessage "Retrieving setting 'userpassword'"; return 1; }

	cp "${resourcesPath}/workman.map" /usr/share/kbd/keymaps/i386/workman.map >> $log 2>&1
	logMessage $? "Copied '${resourcesPath}/workman.map' to '/usr/share/kbd/keymaps/i386/workman.map'" || return 1

	echo "KEYMAP=workman" >> /etc/vconsole.conf 2>> $log
	logMessage $? "Set virtual console keymap in /etc/vconsole.conf" || return 1

	ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime >> $log 2>&1
	logMessage $? "Set local time to Sydney, Australia" || return 1

	hwclock --systohc >> $log 2>&1
	logMessage $? "Generated /etc/adjtime" || return 1

	echo "$hostname" > /etc/hostname 2>> $log
	logMessage $? "Set hostname to '$hostname'" || return 1

	echo -e "127.0.0.1 $hostname\n$hostname\n127.0.0.1 $hostname.localdomain $hostname" >> /etc/hosts 2>> $log
	logMessage $? "Added /etc/hosts entries for hostname '$hostname'" || return 1

	sed -i'' "s/#en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/" /etc/locale.gen >> $log 2>&1
	logMessage $? "Uncommented en_AU locale in /etc/locale.gen for locale generation" || return 1

	locale-gen >> $log 2>&1
	logMessage $? "Generated en_AU locale" || return 1

	echo "LANG=en_AU.UTF-8" > /etc/locale.conf 2>> $log
	logMessage $? "Set LANG var in /etc/locale.conf" || return 1

	pacman -Syy >> $log 2>&1
	logMessage $? "Retrieving current package databases" || return 1

	tentativeMessage "Retrieving and installing refind-efi package"
	pacman -Syy --noconfirm refind-efi >> $log 2>&1
	logMessage $? "Retrieved and installed refind-efi package" || return 1

	tentativeMessage "Retrieving and installing intel-ucode package"
	pacman -Syy --noconfirm intel-ucode >> $log 2>&1
	logMessage $? "Retrieved and installed intel-ucode package" || return 1

	refind-install --usedefault /dev/sda1 >> $log 2>&1
	logMessage $? "Installed rEFInd boot manager using default of /dev/sda1" || return 1

	sed -i'' "s/^timeout 20$/timeout 3/" "/boot/efi/EFI/BOOT/refind.conf" >> $log 2>&1
	logMessage $? "Set rEFInd boot menu timeout to 3 seconds" || return 1

	mkrlconf >> $log 2>&1
	logMessage $? "Generated /boot/refind_linux.conf with mkrlconf" || return 1

	partuuid=$(blkid --output export | grep -A3 sda2 | grep PARTUUID | cut -c10-)
	echo "\"Arch Linux\" \"rw root=PARTUUID=${partuuid} rootfstype=ext4 initrd=/boot/intel-ucode.img initrd=/boot/initramfs-linux.img\"" > /boot/refind_linux.conf 2>> $log
	logMessage $? "Set PARTUUID of root partition in /boot/refind_linux.conf" || return 1

	echo "root:${rootpassword}" | chpasswd >> $log 2>&1
	logMessage $? "Set password for root user" || return 1

	useradd -m -s /bin/bash $username >> $log 2>&1
	logMessage $? "Added '${username}' user" || return 1

	echo "${username}:${userpassword}" | chpasswd >> $log 2>&1
	logMessage $? "Set password for user '${username}'" || return 1

	sed -i'' "s/^hostname$/${hostname}/" "/etc/dhcpcd.conf" >> $log 2>&1
	logMessage $? "Set hostname to ${hostname} in /etc/dhcpcd.conf" || return 1

	systemctl enable dhcpcd@enp0s3.service >> $log 2>&1
	logMessage $? "Set dhcpcd to start for enp0s3 interface at boot" || return 1

	tentativeMessage "Retrieving and installing sudo package"
	pacman -Syy --noconfirm sudo >> $log 2>&1
	logMessage $? "Retrieved and installed sudo package" || return 1

	tentativeMessage "Retrieving and installing virtualbox-guest-modules-arch, virtualbox-guest-utils packages"
	pacman -Syy --noconfirm virtualbox-guest-modules-arch virtualbox-guest-utils >> $log 2>&1
	logMessage $? "Retrieved and installed virtualbox-guest-modules-arch, virtualbox-guest-utils packages" || return 1

	tentativeMessage "Retrieving and installing xorg, xorg-xinit, xterm packages"
	pacman -Syy --noconfirm xorg xorg-xinit xterm >> $log 2>&1
	logMessage $? "Retrieved and installed xorg, xorg-xinit, xterm packages" || return 1

	echo "setxkbmap -variant workman" > ~/.xinitrc 2>> $log
	logMessage $? "Set X to use Workman keymap in ~/.xinitrc" || return 1

	tentativeMessage "Retrieving and installing i3-wm package"
	pacman -Syy --noconfirm i3-wm >> $log 2>&1
	logMessage $? "Retrieved and installed i3-wm package" || return 1

	echo "exec i3" >> ~/.xinitrc 2>> $log
	logMessage $? "Set startx to launch i3 in ~/.xinitrc" || return 1

	return 0
}

main "$@"