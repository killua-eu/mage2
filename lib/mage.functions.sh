#!/usr/bin/env bash


chrooted() {
  if [ "$(stat -c %d/%i /)" = "$(stat -Lc %d/%i /proc/1/root 2>/dev/null)" ];
  then
    # the devicenumber/inode pair of / is the same as that of /sbin/init's
    # root, so we're *not* in a chroot and hence return false.
    echo "Not chrooted."
    return 1
  fi
  echo "A chroot environment has been detected."
  return 0
}



firstboot() {
    # firstboot() detects if we're in a chroot and either executes a command, or queues it up
    # into the /var/mage/firstboot file. Here's why:
    # - Installing Gentoo from stage3 requires you to work from a chrooted environment,
    # - Systemd won't run in a chrooted environment,
    # - We want to run commands such as systemctl, which require Systemd to run.
    
    # Detect if we're in a chroot
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
        [[ -d "/var/mage" ]] || mkdir -p /var/mage || eexit "Couldn't create /var/mage directory"
        [[ -f "/var/mage/firstboot" ]] || echo '#!/usr/bin/env bash' > /var/mage/firstboot || eexit "Couldn't write to /var/mage/firstboot file"
        echo "$@" >> /var/mage/firstboot
    else
        set -x; "$@"; set +x;
    fi
}



ismounted() {
  mountpoint -q "${1}" && mount | grep "on ${1} " > /dev/null && return 0
  return 1
}


#  
# yesno() returns 0 if the argument  or # the value of the argument 
# is "yes", "true", "on", or "1" or 1 otherwise.
#
yesno() {
  [ -z "$1" ] && return 1

  case "$1" in
    [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
    [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
  esac

  local value=
  eval value=\$${1}
  case "$value" in
    [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
    [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
    *) vewarn "\$$1 is not set properly"; return 1;;
  esac
}


# testcolors() prints several environmental things related to mage

testcolors() {
cat << HELP_END

TESTING COLORS: ${GOOD}GOOD ${WARN}WARN ${BAD}BAD ${HILITE}HILITE ${BRACKET}BRACKET ${BOLD}BOLD ${NORMAL}NORMAL

HELP_END
exit ${1:-1}
}

