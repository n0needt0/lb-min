#!/bin/bash

lb config\
 --apt-indices none\
 --apt-recommends false\
 --architectures armhf\
 --binary-images tar\
 --binary-filesystem ext3\
 --bootloader ""\
 --cache false\
 --chroot-filesystem none\
 --debian-installer-gui false\
 --distribution jessie\
 --parent-distribution jessie\
 --parent-debian-installer-distribution jessie\
 --gzip-options '--best --rsyncable'\
 --initramfs auto\
 --linux-flavours ntc\
 --linux-packages linux-image-4.4.11\
 --bootstrap-qemu-arch armhf\
 --bootstrap-qemu-static /usr/bin/qemu-arm-static

echo -e "\
\#!/bin/bash -x\n\
for i in boot/vmlinuz* ; do\n\
    kernel="$(basename "$i")"\n\
    version="${kernel##vmlinuz-}"\n\
    initrd="boot/initrd.img-${version}"\n\
    [ -f "$initrd" ] || update-initramfs -c -k "$version" || true\n\
done\n\
" > config/hooks/0500-initrd.hook.chroot
