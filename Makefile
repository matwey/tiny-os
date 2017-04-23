include config.mk

BUSYBOX_LINKS:=$(addprefix ${BUILD_DIR}/busybox, $(shell cat ${BUSYBOX_LINKS_FILE}))

all: ${TFTPD_DIR}/zImage ${TFTPD_DIR}/initrd

clean:
	rm -rf ${BUILD_DIR}/busybox
	rm -rf ${BUILD_DIR}/kernel
	rm -rf initrd.cpio
	rm -rf busybox.cpio

modules:
	make -C ${LINUX_SOURCE_DIR} KBUILD_OUTPUT=${LINUX_BUILD_DIR} ARCH=arm CROSS_COMPILE=arm-suse-linux-gnueabi- CC=arm-suse-linux-gnueabi-gcc-6 modules_install INSTALL_MOD_PATH=${BUILD_DIR}/kernel INSTALL_MOD_STRIP=1

${BUILD_DIR}/busybox/%:
	mkdir -p $(shell dirname $@)
	ln -s /usr/bin/busybox $@

busybox.cpio: ${BUSYBOX_STATIC_BIN} ${BUSYBOX_LINKS}
	mkdir -p ${BUILD_DIR}/busybox/usr/bin
	cp ${BUSYBOX_STATIC_BIN} ${BUILD_DIR}/busybox/usr/bin/busybox
	cd ${BUILD_DIR}/busybox && find . -depth -print | cpio -o -H newc -F ${PWD}/$@

initrd.cpio: busybox.cpio modules
	cp $< $@
	cd ${BUILD_DIR}/kernel && find . -depth -print | cpio -o -A -H newc -F ${PWD}/$@

${TFTPD_DIR}/initrd: initrd.cpio
	xz -c - < $< > $@

${TFTPD_DIR}/zImage: ${LINUX_BUILD_DIR}/arch/arm/boot/zImage
	cp $< $@

.phony: all modules clean
