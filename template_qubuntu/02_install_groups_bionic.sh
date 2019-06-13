#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"


#### '--------------------------------------------------------------------------
info 'Update sources.list'
#### '--------------------------------------------------------------------------
updateQubuntuSourceList

aptUpdate

chroot_cmd systemctl disable systemd-resolved
chroot_cmd systemctl mask systemd-resolved

