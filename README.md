# Basic-Arch-Installer

Automate installation of Arch Linux.

* Basic installation, based on the [Installation Guide](https://wiki.archlinux.org/index.php/Installation_guide)
* Unattended, i.e. no interaction required on happy path
* Tested only in VirtualBox at this stage (TODO: test on real hardware)
* Intentionally limited `.ini`-based configuration
	* Fork or make adjustments for further configuration

This project does not aim to be a comprehensive, configurable installer, but instead a simple baseline for my purposes, which may serve as a reference for others with similar needs.

![Screenshot](https://raw.githubusercontent.com/tkf144/basic-arch-installer/github-assets/screenshots/install-in-progress.gif)

## Tasks / Arch Linux Configuration

This script will:

* `bootstrap.sh`
	*  Copy 'resources' (e.g. scripts, configs, keyboard maps) from your HTTP server to the installation
* `install.sh`
	*  Create a basic partitioning scheme; 1 x 500MB FAT32 ESP, and 1 x *remaining_size* root EXT4 FS
	*  Retrieve a current pacman mirror list - generate one at [archlinux.org/mirrorlist](https://www.archlinux.org/mirrorlist/) and place the resulting URL in `settings.ini`
	*  Run [`pacstrap` installer](https://git.archlinux.org/arch-install-scripts.git/tree/pacstrap.in)
	*  Generate `/etc/fstab`
* `configure.sh`
	* Copy and set console to use Workman keyboard map (TODO: make configurable via `settings.ini`)
	* Configure `/etc/localtime` to use Sydney, AU time (TODO: make configurable via `settings.ini`)
	* Configure hostname, using value from `.ini`
	* Configure `/etc/hosts`
	* Generate `en_AU` locale
	* Install `refind-efi` package
	* Install `intel-ucode` package
	* Run `refind-install` script, with `--usedefault /dev/sda`
	* Set root password
	* Add new user; set their password
	* Enable `dhcpcd` service
	* Install `sudo` package
	* Install `virtualbox-guest-modules-arch`, `virtualbox-guest-utils` packages (TODO: make configurable via `settings.ini`)
	* Install `xorg`, `xorg-xinit`, `xterm` packages
	* Configure X to use Workman keyboard layout (TODO: make configurable via `settings.ini`)
	* Install `i3-wm` package
	* Configure `startx` command to launch i3 window manager

## Required

* Arch Linux [installation ISO](https://www.archlinux.org/download/)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (note: this is as yet untested outside VB and contains VB-specific installation steps)
* Some means of running a temporary HTTP server (e.g. Python's `python -m http.server`)
* The contents of this repository

## Use

1. Establish VirtualBox machine for Arch Linux
	* System > `Enable EFI (special OSes only)` = `true`)
	* Storage > 1 optical drive with Arch Linux ISO mounted
	* Storage > 1 HDD with > ~5GB capacity
2. Clone/download this repo
3. Begin serving HTTP from the repo, using `cd <path_to_this_repo>; python -m http.server` for example
4. Start Arch Linux VM
5. Once at the root prompt, enter the following, changing `resourcesUrl=..` to point to your HTTP server. [1]
```
resourcesUrl="http://192.168.1.144:8000";
wget -qO bootstrap.sh "${resourcesUrl}/bootstrap.sh" && chmod 755 bootstrap.sh && ./bootstrap.sh $resourcesUrl
```
6. Allow installer to complete.
7. Shutdown VM
8. Remove Arch Linux ISO from VM optical drive
9. Start VM
10. Confirm:
	* You are presented with a login prompt
	* You can login with the root account and the password specified in `settings.ini`
	* Running `startx` launches `i3-wm`
11. No further action required.

[1] From my Windows 10 host, I have automated this using these commands runnable in Bash; they will need slight modification for use in Windows Command Prompt. This is useful if your preferred keyboard layout is not QWERTY. `keyboardputstring` was introduced to VirtualBox late 2016.
```
"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" controlvm "Arch" keyboardputstring "resourcesUrl="http://192.168.1.144:8000"; wget -qO bootstrap.sh "\${resourcesUrl}/bootstrap.sh" && chmod 755 bootstrap.sh && ./bootstrap.sh \$resourcesUrl" && "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" controlvm "Arch" keyboardputscancode 1c 9c
```

## Configuration

`settings.ini` allows limited configuration.

```
[bootstrapper]
	pacmanmirrorlisturl=https://www.archlinux.org/mirrorlist/?country=AU&protocol=http&protocol=https&ip_version=4

[installation]
	hostname=my-arch-machine
	rootpassword=password
	username=new-user
	userpassword=password
```

## TODO/Future/Ideas/Improvements

* Improvements:
	* [ ] Remove need for local temporary HTTP server
	* [ ] Remove need to specify resources in `bootstrap.sh`
	* [ ] Add means of copying an arbitrary set of files to the new installation, e.g. i3 configs, wallpapers
	* [ ] Add means of specifying additional packages to be installed
	* [ ] Add means of specifying additional scripts to be run
	* [ ] Tests

* Defects/known issues:
	* [ ] Untested outside of VirtualBox
	* [ ] Contains VirtualBox-specific installation steps
	* [ ] There are 2 `log.txt`s at the end of the installation; one for `install.sh` and one for `configure.sh`

## Related Projects

* https://github.com/MatMoul/archfi
* https://github.com/i3-Arch/Arch-Installer
* https://github.com/helmuthdu/aui

## Licence

MIT License

Copyright (c) 2018 TKF144

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.