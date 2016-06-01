#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
echo "" && eselect profile show echo ""

einfo "Emerging package sets"
${SCRIPT} -uDN @mage-desktop-gnome


chrooted() {
  if [ "$(stat -c %d/%i /)" = "$(stat -Lc %d/%i /proc/1/root 2>/dev/null)" ];
  then
    # the devicenumber/inode pair of / is the same as that of /sbin/init's
    # root, so we're *not* in a chroot and hence return false.
    return 1
  fi
  echo "A chroot environment has been detected."
  return 0
}


firstboot einfo "Enabling and starting services"
firstboot systemctl enable gdm.service
firstboot systemctl enable NetworkManager 
firstboot systemctl daemon-reload
firstboot systemctl start avahi-daemon.service
firstboot systemctl start avahi-dnsconfd.service
firstboot systemctl start cups.service
firstboot systemctl start cups-browsed.service
firstboot systemctl enable avahi-daemon.service
firstboot systemctl enable avahi-dnsconfd.service
firstboot systemctl enable cups-browsed.service
firstboot systemctl enable cups.service
