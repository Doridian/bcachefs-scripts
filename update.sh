#!/bin/bash

set -euo pipefail

function update-dep
{
	echo "Adding additional repositories"
	sudo apt-add-repository -syn multiverse
	sudo apt-add-repository -syn universe
	#sudo apt-add-repository -syn restricted
	grep '# deb-src.*main' /etc/apt/sources.list | sed 's|# deb-src|deb-src|g' | sudo tee /etc/apt/sources.list.d/deb-src.list
	echo "Getting new repository information"
	sudo apt update

	echo "Getting bcachefs dependencies"
	sudo apt install -y debootstrap tasksel devscripts gcc git libaio-dev libattr1-dev libblkid-dev libkeyutils-dev liblz4-dev libscrypt-dev libsodium-dev liburcu-dev libzstd-dev make pkg-config uuid-dev zlib1g-dev valgrind python3-pytest binutils-dev

	echo "Getting Linux Kernel Build Dependencies"
	sudo apt build-dep -y linux
}

function update-bcachefs-tools
{
	echo "Setup build direct"
	mkdir -p ~/build
	cd ~/build
	rm -f bcachefs*.deb

	if [ -d bcachefs-tools/.git ]
	then
		echo "Updating Bcachefs Tools"
		cd bcachefs-tools
		git pull
		make clean
		cd ..
	else
		echo "Getting Bcachefs Tools"
		rm -Rf ./bcachefs-tools
		git clone https://evilpiepirate.org/git/bcachefs-tools.git
	fi

	echo "Building Bcachefs Tools"
	cd bcachefs-tools

	make deb -j $(nproc)

	cd ..

	echo "Installing Bcachefs Tools"

	sudo dpkg -i bcachefs*.deb
	sudo apt -f install -y
}

function update-bcachefs
{
	mkdir -p ~/build
	cd ~/build
	rm -Rf ./*.orig
	rm -f linux*.deb

	if [ -d bcachefs/.git ]
	then
		echo "Updating Linux Kernel"
		cd bcachefs
		git pull
		make mrproper
		cd ..
	else
		echo "Getting Linux Kernel"
		rm -Rf ./bcachefs
		git clone https://evilpiepirate.org/git/bcachefs.git
	fi

	echo "Setting Kernel Configuration"

	cd ./bcachefs

	make olddefconfig

	## CONFIG_DEBUG_INFO controls whether or not make will spit out linux-image-blahblah-dbg.deb
	scripts/config --disable CONFIG_DEBUG_INFO
	scripts/config --enable CONFIG_BCACHEFS_FS
	scripts/config --enable CONFIG_BCACHEFS_QUOTA
	scripts/config --enable CONFIG_BCACHEFS_POSIX_ACL
	scripts/config --disable CONFIG_BCACHEFS_DEBUG
	scripts/config --disable CONFIG_BCACHEFS_TESTS

	scripts/config --set-str SYSTEM_REVOCATION_KEYS ''
	scripts/config --set-str SYSTEM_TRUSTED_KEYS ''


	echo "Building Linux Kernel"

	make bindeb-pkg -j $(nproc) EXTRAVERSION=-$(git rev-parse --short HEAD) LOCALVERSION=
	cd ..

	echo "Installing Linux Kernel"

	sudo dpkg -i linux*.deb
	sudo apt -f install -y
}

update-dep
update-bcachefs-tools
update-bcachefs
