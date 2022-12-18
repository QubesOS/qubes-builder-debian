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

##### "=========================================================================
debug " Installing custom packages and customizing ${DIST_CODENAME}"
##### "=========================================================================

#### '--------------------------------------------------------------------------
info ' Adding contrib, non-free and Debian security to repository.'
#### '--------------------------------------------------------------------------
updateDebianSourceList
aptUpdate
