inherit image_types

#
# Create an image that can by written onto a SD card using dd.
# Originally written for rasberrypi adapt for the needs of allwinner sunxi based boards
#
# The disk layout used is:
#
#    0                      -> 8*1024                           - reserverd
#    8*1024                 ->                                  - arm combined spl/u-boot or aarch64 spl
#    40*1024                ->                                  - aarch64 u-boot
#    2048*1024              -> BOOT_SPACE                       - bootloader and kernel
#
#

# This image depends on the rootfs image
IMAGE_TYPEDEP_sunxi-sdimg = "${SDIMG_ROOTFS_TYPE}"

# Boot partition volume id
BOOTDD_VOLUME_ID ?= "${MACHINE}"
# SDIMG_SIZE(KiB)
SD_SIZE ?= "32000"
# Boot partition size [in KiB]
BOOT_SPACE ?= "6144"


# First partition begin at sector 2048 : 2048*1024 = 2097152
IMAGE_ROOTFS_ALIGNMENT = "2048"

# Use an uncompressed ext4 by default as rootfs
SDIMG_ROOTFS_TYPE ?= "ext4"
SDIMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.${SDIMG_ROOTFS_TYPE}"

do_image_sunxi_sdimg[depends] += " \
			parted-native:do_populate_sysroot \
			mtools-native:do_populate_sysroot \
			dosfstools-native:do_populate_sysroot \
			virtual/kernel:do_deploy \
			virtual/bootloader:do_deploy \
			"

# SD card image name
SDIMG = "${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.sunxi-sdimg.img"

IMAGE_CMD_sunxi-sdimg () {





	# Define rootfs partition size as (sdcard_size - bootfs_size):
	# - sdcard_size: SDCARD_SIZE_TARGET in KiB
	# - bootfs_size: BOOT_SPACE in KiB
	# - 100MB:       space needed to reflect the fact that actual SD cards
	#                typically have a smaller capacity than advertised
	SDCARD_SIZE_TARGET=${SD_SIZE}
	ROOTFS_SIZE_TARGET=$(expr ${SDCARD_SIZE_TARGET} - ${BOOT_SPACE} )
	ROOTFS_SIZE=`du -bks ${SDIMG_ROOTFS} | awk '{print $1}'`
	if [ $ROOTFS_SIZE -lt $ROOTFS_SIZE_TARGET ]; then
		ROOTFS_SIZE=$ROOTFS_SIZE_TARGET
        fi


	# Align partitions
	BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
	echo "BOOT_SPACE_ALIGNED:${BOOT_SPACE_ALIGNED}"
        BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
        echo "BOOT_SPACE_ALIGNED:${BOOT_SPACE_ALIGNED}"
	ROOTFS_SIZE=`du -bks ${SDIMG_ROOTFS} | awk '{print $1}'`

        # Round up RootFS size to the alignment size as well
	ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
	ROOTFS_SIZE_ALIGNED=$(expr ${ROOTFS_SIZE_ALIGNED} - ${ROOTFS_SIZE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
	SDIMG_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + ${ROOTFS_SIZE_ALIGNED})

        echo "Creating filesystem with Boot partition ${BOOT_SPACE_ALIGNED} KiB and RootFS ${ROOTFS_SIZE_ALIGNED} KiB"

	# Initialize sdcard image file
        dd if=/dev/zero of=${SDIMG} bs=1024 count=0 seek=${SDIMG_SIZE}



	# Create partition table
	parted -s ${SDIMG} mklabel msdos
	# Create boot partition and mark it as bootable
	parted -s ${SDIMG} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT})
	parted -s ${SDIMG} set 1 boot on
	# Create rootfs partition to the end of disk
	parted -s ${SDIMG} -- unit KiB mkpart primary ${SDIMG_ROOTFS_TYPE} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT}) -1s
  parted ${SDIMG} print

	# Create a vfat image with boot files
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${SDIMG} unit b print | awk '/ 1 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
	rm -f ${WORKDIR}/boot.img
	mkfs.vfat -n "${BOOTDD_VOLUME_ID}" -S 512 -C ${WORKDIR}/boot.img $BOOT_BLOCKS

	mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::${KERNEL_IMAGETYPE}

	# Copy device tree file


	echo "COPY DEVICE TREE"
	mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/sun8i-v3s-licheepi-zero.dtb ::sun8i-v3s-licheepi-zero.dtb
	mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/sun8i-v3s-licheepi-zero-dock.dtb ::sun8i-v3s-licheepi-zero-dock.dtb

	if [ -e "${DEPLOY_DIR_IMAGE}/u-boot.bin" ]
	then
		mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/u-boot.bin ::u-boot.bin
	fi

	if [ -e "${DEPLOY_DIR_IMAGE}/boot.scr" ]
	then
		mcopy -i ${WORKDIR}/boot.img -s ${DEPLOY_DIR_IMAGE}/boot.scr ::

		echo "Co file boot.scr"
	else
		echo "Please run command: bitbake v3s-u-boot-scr"

		echo "Deo Co file boot.scr"
		bbfatal "Please run command: bitbake v3s-u-boot-scr"
	fi

	# Add stamp file
	echo "${IMAGE_NAME}" > ${WORKDIR}/image-version-info
	mcopy -i ${WORKDIR}/boot.img -v ${WORKDIR}/image-version-info ::

	# Burn Partitions
	dd if=${WORKDIR}/boot.img of=${SDIMG} conv=notrunc seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	# If SDIMG_ROOTFS_TYPE is a .xz file use xzcat
	if echo "${SDIMG_ROOTFS_TYPE}" | egrep -q "*\.xz"
	then
		xzcat ${SDIMG_ROOTFS} | dd of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	else
		dd if=${SDIMG_ROOTFS} of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024)
	fi

	# write u-boot-spl at the begining of sdcard in one shot
	SPL_FILE=$(basename ${SPL_BINARY})
	dd if=${DEPLOY_DIR_IMAGE}/${SPL_FILE} of=${SDIMG} bs=1024 seek=8 conv=notrunc
	#ln -sr ${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.sunxi-sdimg.img ${IMGDEPLOYDIR}/sdimg
}

# write uboot.itb for arm64 boards
IMAGE_CMD_sunxi-sdimg_append_sun50i () {
	if [ -e "${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY}" ]
	then
		dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY} of=${SDIMG} bs=1024 seek=40 conv=notrunc
	fi
}
