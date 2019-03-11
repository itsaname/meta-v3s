DESCRIPTION = "CHIP image minimal, to get the hardware running"
LICENSE = "MIT"

require recipes-core/images/core-image-base.bb

IMAGE_INSTALL += " \
"
KERNEL_EXTRA_INSTALL = " \
    kernel-modules \
"

WIFI_SUPPORT = " \
    crda \
    iw \
    linux-firmware-rtl8723 \
    wireless-tools \
    wpa-supplicant \
"
