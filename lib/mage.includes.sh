#!/usr/bin/env bash

# Setup the colors so our messages all look pretty

if yesno "${RC_NOCOLOR}"; then
	unset GOOD WARN BAD NORMAL HILITE BRACKET
elif (command -v tput && tput colors) >/dev/null 2>&1; then
	GOOD="$(tput sgr0)$(tput bold)$(tput setaf 2)"
	WARN="$(tput sgr0)$(tput bold)$(tput setaf 3)"
	BAD="$(tput sgr0)$(tput bold)$(tput setaf 1)"
	HILITE="$(tput sgr0)$(tput bold)$(tput setaf 6)"
	BRACKET="$(tput sgr0)$(tput bold)$(tput setaf 4)"
	NORMAL="$(tput sgr0)"
	BOLD="$(tput sgr0)$(tput bold)"
	MINFO="${BRACKET}** ${NORMAL}"
	MWARN="${WARN}** ${NORMAL}"
	MFAIL="${BAD}!! ${NORMAL}"
	MDONE="${GOOD}** ${NORMAL}"
else
	GOOD=$(printf '\033[32;01m')
	WARN=$(printf '\033[33;01m')
	BAD=$(printf '\033[31;01m')
	HILITE=$(printf '\033[36;01m')
	BRACKET=$(printf '\033[34;01m')
	NORMAL=$(printf '\033[0m')
	HEAD=  $(printf '\033[01m') 
	MINFO="${BRACKET}** ${NORMAL}"
	MWARN="${WARN}** ${NORMAL}"
	MFAIL="${BAD}!! ${NORMAL}"
	MDONE="${GOOD}** ${NORMAL}"
fi

