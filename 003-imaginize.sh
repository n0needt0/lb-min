#!/bin/bash

set -ex

SERVER_UBI_URL=${SERVER_UBI_URL:-"http://opensource.nextthing.co/chippian/rootfs/server-ubi.tar.gz"}
SERVER_UBI_FILENAME=$(echo "${SERVER_UBI_URL}" | sed 's/.*\///')

UBI_BLOCK_SIZE=${UBI_BLOCK_SIZE:-$((2*1024*1024))}

CHIP_UBOOT_BRANCH=${CHIP_UBOOT_BRANCH:-nextthing/2016.01/next}



rm -rf chip-u-boot

mkdir build-serv

git clone https://github.com/nextthingco/chip-u-boot
pushd chip-u-boot

git checkout ${CHIP_UBOOT_BRANCH}

make ${UBOOT_EXTRA_OPTS} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- CHIP_defconfig
make ${UBOOT_EXTRA_OPTS} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j8

cp spl/sunxi-spl.bin ../build-serv/
cp spl/sunxi-spl-with-ecc.bin ../build-serv

cp u-boot-dtb.bin ../

popd

dd if=u-boot-dtb.bin of=padded-u-boot-dtb.bin bs=4M conv=sync

UBOOT_SIZE=`wc -c padded-u-boot-dtb.bin | awk '{printf $1}' | xargs printf "0x%08x"`
dd if=/dev/urandom of=padded-u-boot-dtb.bin seek=$((UBOOT_SIZE / 0x4000)) bs=16k count=$(((0x400000 - UBOOT_SIZE) / 0x4000))

cp padded-u-boot-dtb.bin build-serv/

cp u-boot-dtb.bin build-serv/

pushd build-serv
tar -xf "../build/${SERVER_UBI_FILENAME}"
popd

img2simg build-serv/server-rootfs.ubi.img build-serv/server-sparse.ubi ${UBI_BLOCK_SIZE}

rm *.bin

tar -zcf build-serv.tar.gz build-serv
