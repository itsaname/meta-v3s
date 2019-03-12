DESCRIPTION = "CHIP image minimal, to get the hardware running"
LICENSE = "MIT"

require recipes-core/images/core-image-base.bb



IMAGE_FEATURES += "package-management"


inherit image

CORE_OS += " \
"

KERNEL_EXTRA_INSTALL = " \
    kernel-modules \
"

WIFI_SUPPORT = " \
    crda \
    iw \
    linux-firmware-rtl8723 \
    wpa-supplicant \
"

DEV_SDK_INSTALL = " \
"

DEV_EXTRAS = " \
"

EXTRA_TOOLS_INSTALL = " \
    ethtool \
    i2c-tools \
    iptables \
    netcat \
  "

IMAGE_INSTALL += " \
    ${CORE_OS} \
    ${DEV_SDK_INSTALL} \
    ${DEV_EXTRAS} \
    ${EXTRA_TOOLS_INSTALL} \
    ${KERNEL_EXTRA_INSTALL} \
    ${WIFI_SUPPORT} \
"
