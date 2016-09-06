#!/bin/bash

set -ex

function setup {
	mv rootfs server-rootfs
}

function build_ubifs {
	echo "=> Building UBIFS..."

    mkdir build	
	pushd build

	sudo mkfs.ubifs -d ../server-rootfs/ -e 0x1f8000 -m 0x4000 -c 2000 -o server-rootfs.ubifs.img
	sudo ubinize -m 0x4000 -p 0x200000 -s 16384 -o server-rootfs.ubi.img ../serv-ubinize.cfg

	popd
    sudo chown -R $USER:$USER build
    sudo chmod a+x build
    sudo chmod a+r build/*
	
	pushd build
	
	tar -zcf server-ubi.tar.gz server-rootfs.ubi.img 
	
	popd
	
}

setup
build_ubifs || exit $?

sudo chown -R $USER:$USER *
