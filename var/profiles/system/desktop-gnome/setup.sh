#!/usr/bin/env bash
einfo "Setting profile ..."
eselect profile set "default/linux/amd64/13.0/desktop/gnome/systemd"
echo "" && eselect profile show echo ""

einfo "Emerging package sets"
${BINDIR}/mage.tmerge -uDN @mage-desktop-gnome-base
${BINDIR}/mage.tmerge -uDN @mage-desktop-gnome-tools
${BINDIR}/mage.tmerge -uDN @mage-desktop-gnome-print
${BINDIR}/mage.tmerge -uDN @mage-desktop-gnome-office


firstboot einfo "Enabling and starting services"
firstboot 10desktop-gnome create systemctl enable gdm.service
firstboot 10desktop-gnome append systemctl enable NetworkManager 
firstboot 10desktop-gnome append systemctl daemon-reload
firstboot 10desktop-gnome append systemctl start avahi-daemon.service
firstboot 10desktop-gnome append systemctl start avahi-dnsconfd.service
firstboot 10desktop-gnome append systemctl start cups.service
firstboot 10desktop-gnome append systemctl start cups-browsed.service
firstboot 10desktop-gnome append systemctl enable avahi-daemon.service
firstboot 10desktop-gnome append systemctl enable avahi-dnsconfd.service
firstboot 10desktop-gnome append systemctl enable cups-browsed.service
firstboot 10desktop-gnome append systemctl enable cups.service
