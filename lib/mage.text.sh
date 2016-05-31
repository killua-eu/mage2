#!/usr/bin/env bash

# ##################
# ### Functions ###
# ##################

# eexit function (see tmerge for usage)

eend()
{
if [ ${1} -ne 0 ]; then
    echo -e "${MFAIL} Failed ${BOLD}${2}${NORMAL}"
    exit ${1:-1}
fi
}

eexit()
{
echo -e "${MFAIL} ${1}"
exit 1
}

efail()
{
echo -e "${MFAIL} ${1}"
}


ewarn()
{
echo -e "${MWARN} ${1}"
}

einfo()
{
echo -e "${MINFO} ${1}"
}

edone()
{
echo -e "${MDONE} ${1}"
}


# magetest() prints several environmental things related to mage

