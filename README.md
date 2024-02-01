Some code to build an image that can be booted in qemu. The ESP
for it contains systemd-boot and a UKI with the current system's
kernel and a minimal busybox initrd.

    $ make
    $ qemu-kvm -m 1024 -bios /usr/share/qemu/ovmf-x86_64.bin -hda img

Can also "chroot" into the just build initrd

    $ ./bwrap-chroot d
