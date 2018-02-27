include config.mk

export PATH := /opt/gcc-linaro-4.8-2015.06-x86_64_arm-linux-gnueabihf/bin:$(PATH)
export KBUILD_OUTPUT := /home/matwey/lab/build

BUSYBOX_LINKS:=$(addprefix ${BUILD_DIR}/busybox, $(shell cat ${BUSYBOX_LINKS_FILE}))

all: ${TFTPD_DIR}/zImage ${TFTPD_DIR}/initrd ${TFTPD_DIR}/${DTB_FILE}

clean:
	rm -rf ${BUILD_DIR}/busybox
	rm -rf ${BUILD_DIR}/kernel
	rm -rf initrd.cpio
	rm -rf busybox.cpio

${LINUX_BUILD_DIR}/arch/arm/boot/zImage:
	make -C ${LINUX_SOURCE_DIR} KBUILD_OUTPUT=${LINUX_BUILD_DIR} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- CC=arm-linux-gnueabihf-gcc zImage

.PHONY: ${BUILD_DIR}/kernel/.modules

${BUILD_DIR}/kernel/.modules:
	rm -rf ${BUILD_DIR}/kernel
	make -C ${LINUX_SOURCE_DIR} KBUILD_OUTPUT=${LINUX_BUILD_DIR} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- CC=arm-linux-gnueabihf-gcc modules_install INSTALL_MOD_PATH=${BUILD_DIR}/kernel INSTALL_MOD_STRIP=1
	touch ${BUILD_DIR}/kernel/.modules

${BUILD_DIR}/busybox/%:
	mkdir -p $(shell dirname $@)
	ln -s /usr/bin/busybox $@

busybox.cpio: ${BUSYBOX_STATIC_BIN} ${BUSYBOX_LINKS} inittab rcS mdev.conf v4l2-test
	mkdir -p ${BUILD_DIR}/busybox/usr/bin
	mkdir -p ${BUILD_DIR}/busybox/{dev,proc,sys,root,run,sysroot,tmp}
	mkdir -p ${BUILD_DIR}/busybox/etc/init.d
	cp rcS ${BUILD_DIR}/busybox/etc/init.d
	cp inittab ${BUILD_DIR}/busybox/etc
	cp mdev.conf ${BUILD_DIR}/busybox/etc
	ln -sf /usr/bin/busybox ${BUILD_DIR}/busybox/init
	ln -sf /sbin/mdev ${BUILD_DIR}/busybox/sbin/hotplug
	cp v4l2-test ${BUILD_DIR}/busybox/bin
#	sudo mknod ${BUILD_DIR}/busybox/dev/null c 1 3
#	sudo mknod ${BUILD_DIR}/busybox/dev/kmsg c 1 11
#	sudo mknod ${BUILD_DIR}/busybox/dev/console c 5 1
	cp ${BUSYBOX_STATIC_BIN} ${BUILD_DIR}/busybox/usr/bin/busybox
	cd ${BUILD_DIR}/busybox && find . -print0 | cpio --null --owner=0:0 -ov --format=newc -F ${PWD}/$@

initrd.cpio: busybox.cpio ${BUILD_DIR}/kernel/.modules
	cp $< $@
	cd ${BUILD_DIR}/kernel && find . -print | cpio -o -A --owner=0:0 -H newc -F ${PWD}/$@

${TFTPD_DIR}/initrd: initrd.cpio
	xz --check=crc32 --lzma2=dict=512KiB -c - < $< > $@

${TFTPD_DIR}/zImage: ${LINUX_BUILD_DIR}/arch/arm/boot/zImage
	cp $< $@

${TFTPD_DIR}/${DTB_FILE}: ${LINUX_BUILD_DIR}/arch/arm/boot/dts/${DTB_FILE}
#${TFTPD_DIR}/${DTB_FILE}: ${LINUX_BUILD_DIR}/arch/arm/boot/dts/am335x-bone.dtb
	cp $< $@

.phony: all clean
