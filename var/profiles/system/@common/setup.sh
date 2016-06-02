#!/usr/bin/env bash
einfo "Emerging package sets"
${BINDIR}/mage.tmerge -uDN @mage-adm-tools @mage-sys-core @mage-sys-fs @mage-sys-net @mage-sys-portage
