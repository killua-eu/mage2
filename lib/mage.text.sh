#!/usr/bin/env bash

# ##################
# ### Functions ###
# ##################

# eexit function (see tmerge for usage)

eend()
{
if [ ${1} -ne 0 ]; then
    echo -e "${MFAIL} Failed ${HILITE}${2}${NORMAL}" | fmt -tw 120 
    exit ${1:-1}
fi
}

eexit()
{
echo -e "${MFAIL} ${1}${NORMAL}" | fmt -tw 120 
exit 1
}

efail()
{
echo -e "${MFAIL} ${1}${NORMAL}" | fmt -tw 120 
}


ewarn()
{
echo -e "${MWARN} ${1}${NORMAL}" | fmt -tw 120 
}

einfo()
{
echo -e "${MINFO} ${1}${NORMAL}" | fmt -tw 120 
}

edone()
{
echo -e "${MDONE} ${1}${NORMAL}" | fmt -tw 120 
}


# magetest() prints several environmental things related to mage

