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


blockfile_exists() {
    echo ""
    einfo "Looking for blockfiles ..."
    while [ "${1+defined}" ]
    do
        [[ -b "$1" ]] && edone "${1}"
        [[ -b "$1" ]] || { 
            efail "${1} not found" 
            error_flag=1
        }
        shift
    done
    [[ ${error_flag} = 1 ]] && eexit "Oops, required blockfiles missing!"
    edone "All good"
    echo ""
    return 0
}


disks_info() {
    echo ""
    einfo "Available storage devices: ${HILITE}`lsblk -d | grep disk | wc -l`${BOLD} (type disk):"
    echo ""
    lsblk -o NAME,FSTYPE,MOUNTPOINT,SIZE,TYPE,ROTA,HOTPLUG,LABEL,PARTLABEL
    echo ""
}


select_script() { # pass path to dir as $1 and default from configuration option as $2
    pushd "${1}" > /dev/null
    shopt -s nullglob
    array=(*)
    shopt -u nullglob # Turn off nullglob to make sure it doesn't interfere with anything later

    for i in "${!array[@]}"; do 
        printf "\n%s\t%s" "${BOLD}[$i]${NORMAL}" "${array[$i]}"
        [[ "${array[$i]}" == "${2}" ]] && printf " ${BRACKET}*${NORMAL}" && default="${array[$i]}"
    done
   
    echo "";
    popd > /dev/null
    einfo "Select preffered option (or just press enter to default to option selected by your bootstrap.conf)"
    
        
    while [[ -z "$selected" ]]
    do
        read -r option; # read user input and use default on enter, if default is set
        if [ -z $x ] ; then
           [[ -n "${default}" ]] && echo "${default}" && selected="${default}"
           [[ -n "${default}" ]] || echo "No default configured, please choose one of the options above and retry."
        else # if a value is given, test if its a number and a valid array item
           [[ "$option" =~ ^[0-9]+$ ]] && [[ -n "${array[$option]}" ]] && selected="${array[$option]}"
           [[ "$option" =~ ^[0-9]+$ ]] && [[ -n "${array[$option]}" ]] || echo "Not a valid option, please retry."
        fi
    done

    local  __resultvar=$3
    eval $__resultvar="'$selected'"
    # fetch the result with: 
    # select_script "some/path/to/scritps" "default_script_name" "returnvar" 
    # echo ${returnvar}
    }
