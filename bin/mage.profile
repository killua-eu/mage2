#!/usr/bin/env bash

# ##################
# ### Load stuff ###
# ##################

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

[ -f "/etc/mage/mage.conf" ] 	&& source "/etc/mage/mage.conf"
[ -f "$DIR/mage.conf" ] 	&& source "$DIR/../etc/mage.conf"

[[ -z ${SCRIPT} ]] && SCRIPT=`readlink -f $0`
[[ -z ${BINDIR} ]] && BINDIR=`dirname "${SCRIPT}"`
[[ -z ${LIBDIR} ]] && LIBDIR="${BINDIR}/../lib"
[[ -z ${VARDIR} ]] && VARDIR="${BINDIR}/../var"
[[ -z ${ETCDIR} ]] && ETCDIR="${BINDIR}/../etc"

for file in ${LIBDIR}/* ; do
  if [ -f "$file" ] ; then
    . "$file"
  fi
done

# ##################
# ### Do stuff   ###
# ##################

[ -f "/etc/portage/make.conf" ] && source "/etc/portage/make.conf"      # include make.conf


case "$1" in
    enable)
        shift 1;
        pushd "${VARDIR}/profiles/${1}" || eexit "No such profile in ${VARDIR}/profiles/"
        response="y"
        [[ -f "/etc/mage/profiles-enabled" ]] && [[ `cat /etc/mage/profiles-enabled | grep "${1}"` ]] && ewarn "Profile ${1} already enabled, really wanna do that again?" && read -r -p "[y/n]: " response
        case $response in
             [yY]) 
                for D in *; do
                    [[ -d "${D}" ]] && cp -r `echo "${D} /etc/portage"`
                done
                popd >> /dev/null
                [[ -d "/etc/mage" ]] || ewarn "/etc/mage directory not present, creating it!" && mkdir -p /etc/mage || eexit "It seems that an /etc/mage *file* exists already. Exitting because of name colision."
                [[ -d "/etc/mage/linuxconfig" ]] || ewarn "/etc/mage/linuxconfig directory not present, creating it!" && mkdir -p /etc/mage/linuxconfig || eexit "It seems that an /etc/mage/linuxconfig *file* exists already. Exitting because of name colision."
                [[ -f "${VARDIR}/profiles/${1}/linuxconfig" ]] && cp "${VARDIR}/profiles/${1}/linuxconfig" "/etc/mage/linuxconfig/`echo ${1} | tr '/' '-'`"
                [[ -f "${VARDIR}/profiles/${1}/setup.sh" ]] && . "${VARDIR}/profiles/${1}/setup.sh"
                echo "${1}" >> /etc/mage/profiles-enabled
            ;;
            *)
                einfo "Doing nothing then"
            ;;
        esac
    ;;
    -h|--help)
        einfo "Usage: ${HILITE}mage.profile enable <profile>${BOLD}"
    ;;
    *)
        eexit "Command ${BOLD}${1}${NORMAL} not recognized, exitting. Try ${BOLD}mage.profile -h${NORMAL}"
    ;;
esac


