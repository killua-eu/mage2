#!/usr/bin/env bash
einfo "Emerging package sets"
current=$(echo `eselect profile show` | sed -e 's/Current \/etc\/portage\/make.profile symlink: //g')
eselect profile set default/linux/amd64/13.0/systemd
${SCRIPT} tmerge -uDN @mage-adm-tools @mage-sys-core @mage-sys-fs @mage-sys-net @mage-sys-portage
eselect profile set $current