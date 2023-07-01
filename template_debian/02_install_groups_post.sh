#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$DEBUG" == "1" ]; then
    set -x
fi

# Source external scripts
# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

if [ "$RELEASE" = "4.1" ]; then
    ##### "=========================================================================
    debug " Keep using pulseaudio on R4.1 - ${DIST_CODENAME}"
    ##### "=========================================================================

    aptInstall pulseaudio
fi
