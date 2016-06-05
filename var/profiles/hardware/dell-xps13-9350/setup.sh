#!/usr/bin/env bash
# https://www.segfault.digital/it/hardware/notebook-dell-xps-13-9350-2015/
# http://www.ultrabug.fr/gentoo-linux-on-dell-xps-13-9350/
# https://vanderzee.org/linux/gentoo-on-xps13-2016-9350-qhd-touchscreen

einfo "BIOS configuration"
einfo "Enter BIOS setup through pressing of F2 during startup"
einfo "Turn off Secure Boot"
einfo "Set SATA Operation to AHCI (will break your Windows boot but who cares)"

# adding GRUB_PLATFORMS="efi-64 pc"  to /etc/portage/make.conf
# emerge -uDN world

#reconfigure /etc/default/grub

# https://forums.gentoo.org/viewtopic-t-938502-start-0.html
# https://forums.gentoo.org/viewtopic-t-1040854-start-0.html
# https://wiki.gentoo.org/wiki/Refind

#GRUB_CMDLINE_LINUX="console=tty1 pcie_aspm=force i915.enable_fbc=1 i915.enable_rc6=7 acpi_backlight=vendor"
#GRUB_GFXMODE=3200x1800
#GRUB_GFXPAYLOAD_LINUX=keep