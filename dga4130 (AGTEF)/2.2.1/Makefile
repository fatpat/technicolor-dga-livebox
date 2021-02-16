D=chroot-1.0.3
ARCHIVE=$D.tar.gz
FIRMWARE_DIR=../firmwares
FIRMWARE=AGTEF_1.0.3_CLOSED.bin
FIRMWARE_EXTRACTED=_${FIRMWARE}.extracted
FILES=usr/sbin/odhcpc bin/sh bin/busybox bin/ubus bin/ipcalc.sh usr/bin/jshn usr/bin/awk lib/ld-uClibc-0.9.33.2.so lib/ld-uClibc.so.0 lib/libuClibc-0.9.33.2.so lib/libc.so.0 lib/libgcc_s.so.1 lib/libcrypt-0.9.33.2.so lib/libcrypt.so.0 lib/libm-0.9.33.2.so lib/libm.so.0 lib/libubus.so lib/libblobmsg_json.so lib/libubox.so usr/lib/libjson-c.so.2.0.1 usr/lib/libjson-c.so.2
RSYNC=rsync -ma --prune-empty-dirs --include "*/"

${ARCHIVE}: ${FILES}
	mkdir -p $D/dev
ifeq (,$(wildcard $D/dev/null))
	sudo mknod -m 444 $D/dev/null c 1 3
endif
ifeq (,$(wildcard $D/dev/zero))
	sudo mknod -m 444 $D/dev/zero c 1 5
endif
ifeq (,$(wildcard $D/dev/random))
	sudo mknod -m 444 $D/dev/random c 1 8
endif
ifeq (,$(wildcard $D/dev/urandom))
	sudo mknod -m 444 $D/dev/urandom c 1 9
endif
	mkdir -p $D/var
	mkdir -p $D/usr/share/libubox
	mkdir -p $D/lib/netifd
	touch $D/lib/functions.sh
	mkdir -p $D/etc
ifeq (,$(wildcard $D/etc/TZ))
	ln -s /tmp/TZ $D/etc/TZ
endif
	echo "/var                /$D/var                none  bind     0  0" >  $D/etc/fstab
	echo "/lib/netifd         /$D/lib/netifd         none  bind,ro  0  0" >> $D/etc/fstab
	echo "/usr/share/libubox  /$D/usr/share/libubox  none  bind,ro  0  0" >> $D/etc/fstab
	echo "/lib/functions.sh   /$D/lib/functions.sh   none  bind,ro  0  0" >> $D/etc/fstab
	tar --owner=0 --group=0 -czpf $@ $D usr

${FILES}: ${FIRMWARE_EXTRACTED}
ifeq (,$(wildcard $D/$@))
	${RSYNC} --include="$@" --exclude="*" ${FIRMWARE_EXTRACTED}/squashfs-root/ $D
endif

${FIRMWARE_EXTRACTED}: ${FIRMWARE_DIR}/${FIRMWARE}
	binwalk -Mre $<

.PHONY: clean cleanall
clean:
	rm -rf ${FIRMWARE_EXTRACTED}
cleanall: clean
	rm -rf $D ${ARCHIVE} ${FIRMWARE_EXTRACTED}
