# meta-v3s
build yocto for allwiner v3s

git clone git://git.yoctoproject.org/poky.git -b sumo
git clone git://git.openembedded.org/openembedded-core -b sumo
git clone git://github.com/openembedded/meta-openembedded.git -b sumo
git clone git://github.com/meta-qt5/meta-qt5.git -b sumo

cd poky
sourec oe-init-build-env
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-qt5
