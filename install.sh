#!/bin/bash

# MIT License Copyright (c) 2018 TKF144 https://github.com/tkf144/basic-arch-installer

function main()
{
	resourcesPath=$1
	log=$2
	pacmanMirrorListUrl=$(getSetting "pacmanmirrorlisturl") || { failMessage "Retrieving setting 'pacmanmirrorlisturl'"; return 1; }

	loadkeys $resourcesPath/workman.map >> $log 2>&1
	logMessage $? "Loaded Workman keymap for duration of installation only"

	timedatectl set-ntp true >> $log 2>&1
	logMessage $? "Set date and time to use NTP (Network Time Protocol)"

	#fdisk commands
		# g - create new empty GPT partition table
		# n - add a new partition
		# w - save and exit
	fdisk /dev/sda <<<"g
	n


	+500M
	t
	1
	n



	w" >> $log 2>&1
	logMessage $? "Created 2 partitions; 1x500MB ESP and 1 primary partition" || return 1
	# ST3 heredoc syntax highlighting is broken: fix = "

	mkfs.fat -F32 /dev/sda1 >> $log 2>&1
	logMessage $? "Created FAT32 boot filesystem on /dev/sda1" || return 1

	mkfs.ext4 /dev/sda2 >> $log 2>&1
	logMessage $? "Created ext4 root filesystem on /dev/sda2" || return 1

	mount /dev/sda2 /mnt >> $log 2>&1
	logMessage $? "Mounted root filesystem on /dev/sda2 at /mnt" || return 1

	mkdir -p /mnt/boot/efi >> $log 2>&1
	logMessage $? "Created /mnt/boot/efi directory" || return 1

	mount /dev/sda1 /mnt/boot/efi >> $log 2>&1
	logMessage $? "Mounted boot filesystem on /dev/sda1 at /mnt/boot/efi" || return 1

	wget -qO "/etc/pacman.d/mirrorlist" $pacmanMirrorListUrl >> $log 2>&1
	logMessage $? "Retrieved current pacman mirrorlist" || return 1

	sed -i'' "s/#Server =/Server =/" "/etc/pacman.d/mirrorlist" >> $log 2>&1
	logMessage $? "Uncommented mirrors in /etc/pacman.d/mirrorlist" || return 1

	tentativeMessage "Retrieving and installing ~237MB of base packages"
	pacstrap /mnt base >> $log 2>&1
	logMessage $? "Retrieved and installed ~237MB of base packages" || return 1

	genfstab -U /mnt >> /mnt/etc/fstab 2>> $log
	logMessage $? "Generated filesystem table in /mnt/etc/fstab" || return 1

	cp -r $resourcesPath /mnt >> $log 2>&1
	logMessage $? "Copied installation resources to /mnt/${resourcesPath}" || return 1

	arch-chroot /mnt echo "A test echo command run via arch-chroot" >> $log 2>&1
	logMessage $? "Test chroot into new installation in /mnt" || return 1

	#mntResourcesPath=$(basename $resourcesPath)
	arch-chroot /mnt "/$(basename $resourcesPath)/configure.sh" "${log}" 2>> $log
	logMessage $? "Chroot-ed to /mnt and configured new installation" || return 1

	return 0
}

main "$@" \
	&& successMessage "Complete. Remove install media and reboot." \
	|| { failMessage "Installation and configuration failed. See ${2} (tail below)."; \
		echo "--------------------------"; \
		tail -20 "${2}"; \
		echo "--------------------------"; \
		exit 1; }