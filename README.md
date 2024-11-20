Some code to build an image that can be booted in qemu. The ESP
can either contain

 - systemd-boot and a UKI with the current system's kernel and a minimal
   busybox initrd
 - or a fit image with kernel and initrd

Build it natively or in the created container

aarch64:

    # apt-get build-dep .
    $ make ARCH=aarch64 do_fit=1
    $ uboot=/path/to/u-boot-qemuarm64/u-boot.bin ARCH=aarch64 ./runqemu

x86_64:

    $ make
    $ qemu-kvm -m 1024 -bios /usr/share/qemu/ovmf-x86_64.bin -hda img

Can also "chroot" into the just build initrd

    $ ./bwrap-chroot initrd-busybox.d
