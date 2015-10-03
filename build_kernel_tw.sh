#!/bin/bash
BASE_DIR=/home/android/Dev
KBASE_NM=Googy-Max-N4-Kernel

export CROSS_COMPILE=/usr/lib/linaro/toolchain-a15/arm-cortex_a15-linux-gnueabihf-linaro_4.9.4-2015.06/bin/arm-linux-gnueabihf-
RAMFS_TMP="$BASE_DIR/$KBASE_NM/Ramdisk_tmp/tmp"
VER="\"-$KBASE_NM-v$1\""
export RAMFS_SOURCE="$BASE_DIR/$KBASE_NM/Ramdisk"

export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export USE_SEC_FIPS_MODE=true

cp -f $BASE_DIR/$KBASE_NM/arch/arm/configs/0googymax_exynos5433-trelte_defconfig $BASE_DIR/$KBASE_NM/0googymax_exynos5433-trelte_defconfig
sed "s#^CONFIG_LOCALVERSION=.*#CONFIG_LOCALVERSION=$VER#" $BASE_DIR/$KBASE_NM/0googymax_exynos5433-trelte_defconfig > $BASE_DIR/$KBASE_NM/arch/arm/configs/0googymax_exynos5433-trelte_defconfig

export KCONFIG_NOTIMESTAMP=true
export ARCH=arm
export SUB_ARCH=arm

make ARCH=arm 0googymax_exynos5433-trelte_defconfig || exit 1

. $KERNELDIR/.config

cd $KERNELDIR/

make exynos5433-tre_eur_open_16.dtb || exit 1

make -j4 zImage || exit 1
tools/dtbToolCM -o dt.img -s 2048 -p scripts/dtc/ arch/arm/boot/dts/ || exit 1

# make -j4 || exit 1

#  CONFIG_DEBUG_SECTION_MISMATCH=y

#remove previous ramfs files
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
rm -rf $RAMFS_TMP/*
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
#clear git repositories in ramfs
find $RAMFS_TMP -name .git -exec rm -rf {} \;
#remove orig backup files
# find $RAMFS_TMP -name .orig -exec rm -rf {} \;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
# mkdir -p /home/googy/Kernel/Googy-Max-N4/Release/system/lib/modules
# rm -rf /home/googy/Kernel/Googy-Max-N4/Release/system/lib/modules/*
# find -name '*.ko' -exec cp -av {} /home/googy/Kernel/Googy-Max-N4/Release/system/lib/modules/ \;
# ${CROSS_COMPILE}strip --strip-unneeded /home/googy/Kernel/Googy-Max-N4/Release/system/lib/modules/*

cd $RAMFS_TMP
find | fakeroot cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
gzip -9 $RAMFS_TMP.cpio
cd -

chmod a+r tools/dt.img

tools/mkbootimg --kernel $KERNELDIR/arch/arm/boot/zImage --dt tools/dt.img --ramdisk /home/googy/Kernel/Googy-Max-N4/Ramdisk_tmp/tmp.cpio.gz --base 0x10000000 --kernel_offset 0x10000000 --ramdisk_offset 0x10008000 --tags_offset 0x10000100 --pagesize 2048 -o $KERNELDIR/boot.img

# tools/mkbootimg --kernel $KERNELDIR/arch/arm/boot/zImage --dt $KERNELDIR/dt.img --ramdisk /home/googy/Kernel/Googy-Max-N4/Ramdisk_tmp/tmp.cpio.gz --base 0x10000000 --kernel_offset 0x10000000 --ramdisk_offset 0x10008000 --tags_offset 0x10000100 --pagesize 2048 -o boot.img || exit 1

cd /home/googy/Kernel/Googy-Max-N4
mv -f -v /home/googy/Kernel/Googy-Max-N4/Kernel/boot.img /home/googy/Kernel/Googy-Max-N4/Release/boot.img
cd /home/googy/Kernel/Googy-Max-N4/Release
zip -r ../Googy-Max-N4_Kernel_${1}_CWM.zip .

adb push /home/googy/Kernel/Googy-Max-N4/Googy-Max-N4_Kernel_${1}_CWM.zip /storage/sdcard0/Googy-Max-N4_Kernel_${1}_CWM.zip

# adb push /home/googy/Anas/Googy-Max4-Kernel/GoogyMax4_TW-Kernel_${1}_CWM.zip /storage/sdcard0/update-gmax4.zip
# 
# adb shell su -c "echo 'boot-recovery ' > /cache/recovery/command"
# adb shell su -c "echo '--update_package=/storage/sdcard0/update-gmax4.zip' >> /cache/recovery/command"
# adb shell su -c "reboot recovery"

adb kill-server
