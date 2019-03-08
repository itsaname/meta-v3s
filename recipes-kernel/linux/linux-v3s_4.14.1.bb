
require recipes-kernel/linux/linux-v3s.inc
DESCRIPTION = "Linux kernel for v3s"
KERNEL_IMAGETYPE = "zImage"

COMPATIBLE_MACHINE = "(v3s)"

KERNEL_DEVICETREE = " \
    sun8i-v3s-licheepi-zero.dtb \
    sun8i-v3s-licheepi-zero-dock.dtb \
"

PV = "4.14.1"
PR = "r0"

SRCREV_pn-${PN} = "${AUTOREV}"

SRC_URI += "https://github.com/itsaname/linux-4.14.x.git;protocol=https"

S = "${WORKDIR}/git/"
LDFLAGS = ""
TARGET_LDFLAGS = ""
B = "${S}"
