all: img

img: esp
	rm -f img img.efivars
	systemd-repart --definitions $(PWD)/repart.d --offline=1 --empty=create --size=500M img

esp: splash.bmp initrd efi-stamp
	./mkesp

efi-stamp:
	./mkefi && > efi-stamp

initrd-busybox:
	./mkinitrd

initrd: initrd-busybox
	zstd -3 -T0 -q < initrd-busybox > initrd

splash.bmp: /usr/share/pixmaps/distribution-logos/square-hicolor.svg
	convert -background black $< $@

clean:
	rm -rf splash.bmp img esp efi efi-stamp initrd initrd-busybox

.PHONY: all clean
