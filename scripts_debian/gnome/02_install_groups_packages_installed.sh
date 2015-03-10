#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing Gnome'
#### '----------------------------------------------------------------------
#packages="$(chroot tasksel --new-install --task-packages desktop)"
#packages+=" $(chroot tasksel --new-install --task-packages gnome-desktop)"
packages="$(chroot tasksel --new-install --task-packages gnome-desktop)"
aptInstall ${packages}
