#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing XFCE'
#### '----------------------------------------------------------------------
read -r -a packages <<<"$(chroot_cmd tasksel --new-install --task-packages xfce-desktop)"
aptInstall "${packages[@]}"
