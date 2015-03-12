#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '-------------------------------------------------------------------------
debug ' Installing qubes-whonix package(s)'
##### '-------------------------------------------------------------------------


# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_qubes" "prepared_qubes installataion has not completed!... Exiting"

# Create system mount points.
prepareChroot


#### '--------------------------------------------------------------------------
info ' Trap ERR and EXIT signals and cleanup (umount)'
#### '--------------------------------------------------------------------------
trap cleanup ERR
trap cleanup EXIT

#### '--------------------------------------------------------------------------
info ' Installing qubes-whonix and other required packages'
#### '--------------------------------------------------------------------------
# whonix-setup-wizard expects '/usr/local/share/applications' directory to exist
chroot mkdir -p '/usr/local/share/applications'  # whonix-setup-wizard needs this

installQubesRepo
aptInstall python-guimessages whonix-setup-wizard qubes-whonix
uninstallQubesRepo

#### '--------------------------------------------------------------------------
info ' Cleanup'
#### '--------------------------------------------------------------------------
umount_all "${INSTALLDIR}/" || true
trap - ERR EXIT
trap
