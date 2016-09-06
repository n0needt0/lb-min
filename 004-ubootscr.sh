#!/bin/bash

set -x

PADDED_UBOOT_SIZE=0x400000

UBOOT_MEM_ADDR=0x4a000000
SPL_MEM_ADDR=0x43000000
UBI_MEM_ADDR=0x4b000000
NO_LIMIT=""

prepare_uboot_script() {
	echo "nand erase.chip" > "${UBOOT_SCRIPT_SRC}"

	echo "echo nand write.raw.noverify $SPL_MEM_ADDR 0x0 $PADDED_SPL_SIZE" >> "${UBOOT_SCRIPT_SRC}"
	echo "nand write.raw.noverify $SPL_MEM_ADDR 0x0 $PADDED_SPL_SIZE" >> "${UBOOT_SCRIPT_SRC}"
	echo "echo nand write.raw.noverify $SPL_MEM_ADDR 0x400000 $PADDED_SPL_SIZE" >> "${UBOOT_SCRIPT_SRC}"
	echo "nand write.raw.noverify $SPL_MEM_ADDR 0x400000 $PADDED_SPL_SIZE" >> "${UBOOT_SCRIPT_SRC}"

	echo "nand write $UBOOT_MEM_ADDR 0x800000 $PADDED_UBOOT_SIZE" >> "${UBOOT_SCRIPT_SRC}"
	echo "setenv bootargs root=ubi0:rootfs rootfstype=ubifs rw earlyprintk ubi.mtd=4" >> "${UBOOT_SCRIPT_SRC}"
	echo "setenv bootcmd 'echo CHIP ID: chip-\${serial#} ;${NO_LIMIT}gpio set PB2; if test -n \${fel_booted} && test -n \${scriptaddr}; then echo '(FEL boot)'; source \${scriptaddr}; fi; mtdparts; ubi part UBI; ubifsmount ubi0:rootfs; ubifsload \$fdt_addr_r /boot/sun5i-r8-chip.dtb; ubifsload \$kernel_addr_r /boot/zImage; setenv bootargs \$bootargs \$kernelarg_video; bootz \$kernel_addr_r - \$fdt_addr_r'" >> "${UBOOT_SCRIPT_SRC}"
  echo "setenv fel_booted 0" >> "${UBOOT_SCRIPT_SRC}"

  echo "echo Enabling Splash" >> "${UBOOT_SCRIPT_SRC}"
  echo "setenv stdout serial" >> "${UBOOT_SCRIPT_SRC}"
  echo "setenv stderr serial" >> "${UBOOT_SCRIPT_SRC}"
  echo "setenv splashpos m,m" >> "${UBOOT_SCRIPT_SRC}"

  echo "setenv dip_addr_r 0x43400000" >>"${UBOOT_SCRIPT_SRC}"
  echo "setenv dip_overlay_dir /lib/firmware/nextthingco/chip/early" >>"${UBOOT_SCRIPT_SRC}"
  echo "setenv dip_overlay_cmd 'if test -n \"\${dip_overlay_name}\"; then ubifsload \$dip_addr_r \$dip_overlay_dir/\$dip_overlay_name; fi'" >>"${UBOOT_SCRIPT_SRC}"

  echo "saveenv" >> "${UBOOT_SCRIPT_SRC}"

  if [[ "${METHOD}" == "fel" ]]; then
	  echo "nand write.slc-mode.trimffs $UBI_MEM_ADDR 0x1000000 $UBI_SIZE" >> "${UBOOT_SCRIPT_SRC}"
	  echo "mw \${scriptaddr} 0x0" >> "${UBOOT_SCRIPT_SRC}"
  else
    echo "echo going to fastboot mode" >>"${UBOOT_SCRIPT_SRC}"
    echo "fastboot 0" >>"${UBOOT_SCRIPT_SRC}"
  fi

    echo "echo " >>"${UBOOT_SCRIPT_SRC}"
    echo "echo *****************[ FLASHING DONE ]*****************" >>"${UBOOT_SCRIPT_SRC}"
    echo "echo " >>"${UBOOT_SCRIPT_SRC}"
      echo "while true; do; sleep 10; done;" >>"${UBOOT_SCRIPT_SRC}"

	mkimage -A arm -T script -C none -n "flash CHIP" -d "${UBOOT_SCRIPT_SRC}" "${UBOOT_SCRIPT}"
}

#deskfel
#PADDED_SPL_SIZE=$(wc -c $PWD/build-desk/sunxi-spl-with-ecc.bin | awk '{printf $1}' | xargs printf "0x%08x")
PADDED_SPL_SIZE=$( echo "196" | awk '{printf $1}' | xargs printf "0x%08x")
#UBI_SIZE=$(wc -c $PWD/build-desk/desktop-rootfs.ubi.img | awk '{printf $1}' | xargs printf "0x%08x")
#UBOOT_SCRIPT_SRC="$PWD/build-desk/uboot-fel.cmds"
#UBOOT_SCRIPT="$PWD/build-desk/uboot-fel.scr"
#METHOD=${METHOD:-fel}

#prepare_uboot_script

#deskfast
UBI_SIZE=$(wc -c $PWD/build-desk/desktop-sparse.ubi | awk '{printf $1}' | xargs printf "0x%08x")
UBOOT_SCRIPT_SRC="$PWD/build-desk/uboot-fastboot.cmds"
UBOOT_SCRIPT="$PWD/build-desk/uboot-fastboot.scr"
METHOD=""

#prepare_uboot_script

#deskfastnolim
cp -r $PWD/build-desk $PWD/build-desk-nl
NO_LIMIT="while itest.b *0x80400000 -ne 03; do i2c mw 0x34 0x30 0x03; i2c read 0x34 0x30 1 0x80400000; done; "
UBI_SIZE=$(wc -c $PWD/build-desk-nl/desktop-sparse.ubi | awk '{printf $1}' | xargs printf "0x%08x")
UBOOT_SCRIPT_SRC="$PWD/build-desk-nl/uboot-fastboot.cmds"
UBOOT_SCRIPT="$PWD/build-desk-nl/uboot-fastboot.scr"
METHOD=""
#prepare_uboot_script

#servfel
#PADDED_SPL_SIZE=$(wc -c $PWD/build-serv/sunxi-spl-with-ecc.bin | awk '{printf $1}' | xargs printf "0x%08x")
UBI_SIZE=$(wc -c $PWD/build-serv/server-rootfs.ubi.img | awk '{printf $1}' | xargs printf "0x%08x")
UBOOT_SCRIPT_SRC="$PWD/build-serv/uboot-fel.cmds"
UBOOT_SCRIPT="$PWD/build-serv/uboot-fel.scr"
METHOD=${METHOD:-fel}

#prepare_uboot_script

#servfast
UBI_SIZE=$(wc -c $PWD/build-serv/server-sparse.ubi | awk '{printf $1}' | xargs printf "0x%08x")
UBOOT_SCRIPT_SRC="$PWD/build-serv/uboot-fastboot.cmds"
UBOOT_SCRIPT="$PWD/build-serv/uboot-fastboot.scr"
METHOD=""

prepare_uboot_script

mkdir -p img-serv-fb/images
cp build-serv/padded-u-boot-dtb.bin 	img-serv-fb/images/padded-u-boot
cp build-serv/sunxi-spl.bin 			img-serv-fb/images/
cp build-serv/sunxi-spl-with-ecc.bin 	img-serv-fb/images/
cp build-serv/server-sparse.ubi 		img-serv-fb/images/rootfs.ubi
cp build-serv/uboot-fastboot.scr 		img-serv-fb/images/uboot.scr
cp build-serv/u-boot-dtb.bin 			img-serv-fb/images/

tar -zvcf img-serv-fb.tar.gz img-serv-fb
