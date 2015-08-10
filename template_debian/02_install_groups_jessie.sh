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
aptUpdate

##### '=========================================================================
debug ' Replacing sysvinit with systemd'
##### '=========================================================================

#### '--------------------------------------------------------------------------
info ' Remove sysvinit'
#### '--------------------------------------------------------------------------
aptRemove sysvinit

#### '--------------------------------------------------------------------------
info ' Install Systemd'
#### '--------------------------------------------------------------------------
aptUpdate
aptInstall systemd-sysv

#### '--------------------------------------------------------------------------
info ' Set multu-user.target as the default target (runlevel 3)'
#### '--------------------------------------------------------------------------
chroot rm -f /etc/systemd/system/default.target
chroot ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
