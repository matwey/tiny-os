include config.mk

BUSYBOX_LINKS:=$(addprefix ${BUILD_DIR}/busybox, $(shell cat ${BUSYBOX_LINKS_FILE}))

all: ${TFTPD_DIR}/zImage ${TFTPD_DIR}/initrd

${BUILD_DIR}/busybox/%:
	mkdir -p $(shell dirname $@)
	ln -s /usr/bin/busybox $@

busybox.cpio: ${BUSYBOX_STATIC_BIN} ${BUSYBOX_LINKS}
	mkdir -p ${BUILD_DIR}/busybox/usr/bin
	cp ${BUSYBOX_STATIC_BIN} ${BUILD_DIR}/busybox/usr/bin/busybox
	$(shell cd ${BUILD_DIR}/busybox; find . -print | cpio -o -H newc -F ${PWD}/$@)

initrd.cpio: busybox.cpio
	cp $< $@

${TFTPD_DIR}/initrd: initrd.cpio
	xz -c - < $< > $@

${TFTPD_DIR}/zImage: ${LINUX_BUILD_DIR}/arch/arm/boot/zImage
	cp $< $@

