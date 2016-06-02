#!/usr/bin/env bash

# TODO QA on this file, compare with uefi.boot+btrfsroot.sh 

#######################
# ### private functions
#######################

disks_banner() {

echo ""
einfo "Single disk with a bios/boot/swap/btrfs root partitioning scheme."
echo ""

}

disks_makepart() {

    einfo "Partitioning ${1} according to a simple ${BOLD}biosboot, boot, swap, root${NORMAL} scheme"
    blockfile_exists "${1}"
    [[ -v MAGE_PARTED_DEF_BIOS ]] || MAGE_PARTED_DEF_BIOS=8M
    [[ -v MAGE_PARTED_DEF_BOOT ]] || MAGE_PARTED_DEF_BOOT=500M
    [[ -v MAGE_PARTED_DEF_SWAP ]] || MAGE_PARTED_DEF_SWAP=12G
    # MAGE_PARTED_DEF_ROOT defined in mage.conf with explanation that it will be ignored here
    # and the rest of the disk's space will be used for the root partition

    parted -a optimal ${1} mklabel gpt                                                             # convert mbr to gpt
    sgdisk -o ${1}                                                                                 # clear partition table
    FS=`sgdisk -F ${1}` ; sgdisk -n 1:${FS}:${MAGE_PARTED_DEF_BIOS} -c 1:"biosboot" -t 1:ef02 ${1} # GRUB partition (4MB)
    FS=`sgdisk -F ${1}` ; sgdisk -n 2:${FS}:${MAGE_PARTED_DEF_BOOT} -c 2:"boot" -t 2:8300 ${1}     # /boot partition (400M)
    FS=`sgdisk -F ${1}` ; sgdisk -n 3:${FS}:${MAGE_PARTED_DEF_SWAP} -c 3:"swap" -t 3:8200 ${1}     # swap partition
    FS=`sgdisk -F ${1}` ; 
    ES=`sgdisk -E ${1}` ; sgdisk -n 4:${FS}:${ES} -c 4:"btrfs" -t 4:8300 ${1}                      # btrfs root partition
    echo ""
    edone "Partitioning done, the resulting scheme is below for your pleasure:"
    sgdisk -p ${1}
    # TODO catch return codes of sgdisk and parted

}

disks_makefs() {
    
    sleep 1
    echo ""
    einfo "Setting up the filesystems"
    echo ""
    
    ### Test if we have the blockfiles
    blockfile_exists "${1}2"
    blockfile_exists "${1}3"
    blockfile_exists "${1}4"
    ### Create filesystems
    mkfs.btrfs -f -L "btrfs" "${1}4" || eexit "mkfs.btrfs (root) failed"
    mkfs.ext4 -L "boot" "${1}2" || eexit "mkfs.ext4 (boot) failed"
    mkswap -L "swap" "${1}3" || eexit "mkswap failed"
    swapon "${1}3" || eexit "swapon failed"
    ### Create the subvolumes on the "${1}4" device
    # Temporarly mount the btrfs volume to /mnt/btrfs
    mkdir -p /mnt/btrfs
    mount -t btrfs -o defaults,noatime,compress=lzo,autodefrag "${1}4" /mnt/btrfs || eexit "Failed mounting /mnt/btrfs"
    sleep 1
    pushd /mnt/btrfs >> /dev/null
    # Create subvolumes
    btrfs subvolume create @         || eexit "Failed creating @ subvolume"
    btrfs subvolume create @/tmp     || eexit "Failed creating @/tmp subvolume"
    btrfs subvolume create @/var     || eexit "Failed creating @/var subvolume"
    btrfs subvolume create @/var/log || eexit "Failed creating @/var/log subvolume"
    btrfs subvolume create @/root    || eexit "Failed creating @/root subvolume"
    btrfs subvolume create @/home    || eexit "Failed creating @/home subvolume"
    btrfs subvolume create PORTAGE   || eexit "Failed creating PORTAGE subvolume"
     
   # Unmount again and remount with options
    popd
    umount /mnt/btrfs    
}    
 
disks_mount() {

    sleep 1
    echo ""
    einfo "Mounting all partitions and subvolumes ..."
    echo ""

    mkdir -p /mnt/gentoo
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@ "${1}4" /mnt/gentoo || eexit "Failed mounting /mnt/gentoo"
    sleep 1
    mkdir -p /mnt/gentoo/{home,root,var,tmp,boot}
    mount "${1}2" /mnt/gentoo/boot || eexit "Failed mounting /mnt/gentoo/boot"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=@/tmp "${1}4" /mnt/gentoo/tmp || eexit "Failed mounting /mnt/gentoo/tmp"
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/var  "${1}4" /mnt/gentoo/var  || eexit "Failed mounting /mnt/gentoo/var" 
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/root "${1}4" /mnt/gentoo/root || eexit "Failed mounting /mnt/gentoo/root" 
    mount -t btrfs -o defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/home "${1}4" /mnt/gentoo/home || eexit "Failed mounting /mnt/gentoo/home"
    mkdir -p /mnt/gentoo/var/log
    mkdir -p /mnt/gentoo/usr/portage
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=@/var/log "${1}4" /mnt/gentoo/var/log || eexit "Failed mounting /mnt/gentoo/var/log"
    mount -t btrfs -o defaults,space_cache,nodatacow,noatime,compress=lzo,autodefrag,subvol=PORTAGE "${1}4" /mnt/gentoo/usr/portage || eexit "Failed mounting mnt/gentoo/usr/portage"
    edone "All partitions and subvolumes mounted."
}   
#nodev,nosuid,noexec
######################
# ### public functions
######################    

disks_do_setup() {    

    einfo "Set the disk to install stuff on (usually /dev/sda)" && read dev1
    disks_makepart "${dev1}"
    # fun fact: nvme partitions have a leading p /dev/nvme01p1, partitions of all other disks do without it /dev/sda1
    [[ `echo "${dev1}" | grep nvme` ]] && dev1="${dev1}p" 
    disks_makefs "${dev1}"
    disks_mount "${dev1}"

}    

disks_do_remount() {    

    einfo "Set the disk to install stuff on (usually /dev/sda)" && read dev1
    # fun fact: nvme partitions have a leading p /dev/nvme01p1, partitions of all other disks do without it /dev/sda1
    [[ `echo "${dev1}" | grep nvme` ]] && dev1="${dev1}p" 
    disks_mount "${dev1}"

}  

disks_do_bootloader() { # used by bootstrap/env to install the bootloader

einfo "Set the disk to install stuff on (usually /dev/*sda*)" && read dev1
# GRUB_CMDLINE_LINUX should only append stuff relevnt to disk partitioning and fstype
# it will be appended via ${1} from the bootstrap/env script with userspace settings (i.e. init=)
echo "GRUB_CMDLINE_LINUX=\"rootfstype=btrfs rootflags=device=/dev/${dev1}4,subvol=@ dobtrfs ${1}\"" >> /etc/default/grub


grub2-install "/dev/${dev1}"
#grub2-install "/dev/${dev2}" # raid1 setup
grub2-mkconfig -o /boot/grub/grub.cfg
echo "
# <fs>              <mountpoint>    <type>      <opts>                                                                         <dump/pass>
LABEL="boot"        /boot           ext4        noauto,noatime                                                                  1 2
LABEL="swap"        none            swap        sw                                                                              0 0
LABEL="btrfs"       /               btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@                   0 0
LABEL="btrfs"       /tmp            btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,nodatacow,subvol=@/tmp     0 0
LABEL="btrfs"       /var            btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/var               0 0
LABEL="btrfs"       /root           btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/root              0 0
LABEL="btrfs"       /home           btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,subvol=@/home              0 0
LABEL="btrfs"       /var/log        btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,nodatacow,subvol=@/var/log 0 0
LABEL="btrfs"       /usr/portage    btrfs       defaults,space_cache,noatime,compress=lzo,autodefrag,nodatacow,subvol=PORTAGE   0 0
" >> /etc/fstab
}
   
    
    
    
# http://www.funtoo.org/BTRFS_Fun
# btrfs filesystem df btrfs/
# btrfs filesystem show /dev/sdd1
# http://hackology.co.uk/2014/btrfs-dual-boot-wankery-arch-ubuntu-grub/
# https://lizards.opensuse.org/2012/10/16/snapper-for-everyone/
# https://wiki.gentoo.org/wiki/Snapper
# https://wiki.archlinux.org/index.php/Snapper
# https://wiki.archlinux.org/index.php/Btrfs_-_Tips_and_tricks
# http://events.linuxfoundation.org/sites/events/files/slides/Btrfs-Rollback-LinuxCon-20150907.pdf
# https://github.com/docker/docker/blob/master/contrib/check-config.sh
# https://medium.com/@ramangupta/why-docker-data-containers-are-good-589b3c6c749e


# TODO
#
#http://migmedia.net/~mig/gentoo-auf-btrfs-root
# nahrad
# /dev/BOOT		/boot		ext2		noauto,noatime	1 2
# v /etc/fstab tak, ze misto /dev/BOOT bude UUID.
# viz take https://wiki.archlinux.org/index.php/fstab#Labels
#
# sed  -e "s_/dev/BOOT_$(blkid -o export /dev/sda2 | sed -n '/^UUID=/ p')_g" -i ./fsb
# cat bak | sed  -e "s_/dev/BOOT_$(blkid -o export /dev/sda2 | sed -n '/^UUID=/ p')_g"
#
# zmeny:
# /etc/fstab menim type bootu z ext2 na ext4
# uz nepisu do /etc/dracut, ale udelam fajl v /etc/dracut.conf.d
#
# dracut '' $(readlink -f /usr/src/linux | sed -e 's!.*linux-!!')

# Copy-on-write comes with some advantages, but can negatively affect performance with large files that have 
# small random writes because it will fragment them (even if no "copy" is ever performed!). It is recommended
# to disable copy-on-write for database files and virtual machine images. 
#
# Snapshotting is still doable even with COW off: http://ram.kossboss.com/btrfs-disabling-cow-file-directory-nodatacow/
#
# Subovlumes instead of directories are superimportant to not allow to roll back certain log-files, databases
# etc. when rolling back the root subvolume. See also:
# https://www.suse.com/documentation/sled-12/book_sle_admin/data/sec_snapper_setup.html#snapper_dir-excludes
#
# /var/lib/mysql, /var/www and other well usable subvolumes should be created by pkg_setup() hooks in 
# /etc/portage/env/pkg-class/pkg-name (http://blog.yjl.im/2014/05/using-epatchuser-to-patch-gentoo.html)
