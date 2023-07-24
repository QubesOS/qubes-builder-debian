#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing GNOME'
#### '----------------------------------------------------------------------
read -r -a packages <<<"$(chroot_cmd tasksel --new-install --task-packages gnome-desktop)"
# Exclude ibus by default, it causes all kind of issues: 
# - spurious tray icon and notification: https://github.com/QubesOS/qubes-issues/issues/8286
# - reordered input events: https://openqa.qubes-os.org/tests/77996#step/clipboard_and_web/8
aptInstall "${packages[@]}" "ibus-"
