ARCH=$(shell uname -m)
KEYNAME=signkey

KCONFIG_CONFIG  ?= .config
export KCONFIG_CONFIG
KCONFIG_AUTOHEADER ?= config.h
export KCONFIG_AUTOHEADER

-include local.mk
-include $(KCONFIG_CONFIG)

ifdef CONFIG_X86_64
	ARCH=x86_64
endif
ifdef CONFIG_ARM64
	ARCH=aarch64
endif
export ARCH

ifeq ($(origin ROOTFS_UUID), undefined)
	ROOTFS_UUID=$(file < img.rootfs_uuid)
	ifeq ($(ROOTFS_UUID),)
		ROOTFS_UUID=$(shell uuidgen)
	endif
endif
export ROOTFS_UUID
export KEYNAME

all: $(KCONFIG_AUTOHEADER) img

rootfs:
	./mkrootfs

img: esp rootfs
	rm -f img img.efivars
	#--offline=1
	#systemd-repart --definitions $(PWD)/repart.d --empty=create --size=500M img
	./creatediskimage img efi rootfs

esp: efi-stamp mkesp
	./mkesp

ifeq ($(CONFIG_FIT),y)
efi-stamp: boot.env.in bootargs.env.in kernel.its mkefi-fit initrd keys/$(KEYNAME).crt
	./mkefi-fit
else
efi-stamp: mkefi initrd
	./mkefi
endif

initrd-busybox: mkinitrd
	./mkinitrd $@

initrd: initrd-busybox
	#gzip -9 < initrd-busybox > initrd
	zstd -3 -T0 -q < initrd-busybox > initrd

ifneq ($(CONFIG_FIT),y)
splash.bmp: /usr/share/pixmaps/distribution-logos/square-hicolor.svg
	convert -background black $< $@
endif

kernel.its: kernel.its.in config.h
	$(CPP) -nostdinc -include config.h -D__ASSEMBLY__ -undef -D__DTS__ -x assembler-with-cpp -o $@ $<

#%.scr: %.env
#	mkimage -f auto -A arm64 -T script -C none -n 'U-Boot script' -d $< $@

# does not work. boot script needs to take built in dt of qemu
#qemu.dts:
#	qemu-system-aarch64 -machine virt -machine dumpdtb=qemu.dtb
#	dtc -I dtb qemu.dtb | grep -v /dts-v1/ > qemu.dts
#
#dt.dtb: dt.dts qemu.dts
#	cat dt.dts qemu.dts | dtc - -o $@
#	#dtc $< -o $@

private.pem:
	openssl ecparam -genkey -name prime256v1 -noout -out $@
	openssl ec -in $< -pubout -out $@

keys/$(KEYNAME).crt:
	mkdir -p keys
	openssl genpkey -algorithm RSA -out keys/$(KEYNAME).key
	#openssl pkey -in private.pem -out public.pem -pubout
	openssl req -batch -new -x509 -key keys/$(KEYNAME).key -out keys/$(KEYNAME).crt

keys: keys/$(KEYNAME).crt

qemu: all
	./runqemu

clean:
	rm -rf splash.bmp img esp efi efi-stamp rootfs initrd initrd-busybox

.PHONY: all clean qemu keys menuconfig

menuconfig:
	kconfig mconf Kconfig

$(KCONFIG_CONFIG): Kconfig
	@if [ -e .config ]; then kconfig conf --oldconfig Kconfig; else kconfig conf --alldefconfig Kconfig; fi

$(KCONFIG_AUTOHEADER): $(KCONFIG_CONFIG)
	sed -ne '/^CONFIG_/{s/=y$$/=1/;s/^\(CONFIG_[^=]\+\)=\(.*\)/#define \1 \2/;p}' < $^ > $@
