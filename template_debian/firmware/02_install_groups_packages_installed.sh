#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Installing firmware'
#### '----------------------------------------------------------------------
chroot_cmd sh -c 'echo "firmware-ipw2x00 firmware-ipw2x00/license/accepted select true" |debconf-set-selections'
read -r -a packages <<<"atmel-firmware firmware-ath9k-htc firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-misc-nonfree firmware-ralink firmware-realtek firmware-zd1211"
aptInstall "${packages[@]}"
