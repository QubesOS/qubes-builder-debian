#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Installing selected packages from qubes-vm-recommended in focal
##### "=========================================================================

updateQubuntuSourceList
aptUpdate
installPackages ${SCRIPTSDIR}/packages_qubes_focal.list
