#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Installing custom packages and customizing ${DIST}"
##### "=========================================================================

#### '--------------------------------------------------------------------------
info ' Adding contrib, non-free and Debian security to repository.'
#### '--------------------------------------------------------------------------
updateDebianSourceList

#### '----------------------------------------------------------------------
info ' Adding jessie backports repository.'
#### '----------------------------------------------------------------------
mirror="$(cat ${INSTALLDIR}/${TMPDIR}/.mirror)"
source="deb ${mirror} jessie-backports main"
if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
    touch "${INSTALLDIR}/etc/apt/sources.list"
    echo -e "$source\n" >> "${INSTALLDIR}/etc/apt/sources.list"
fi
aptUpdate
