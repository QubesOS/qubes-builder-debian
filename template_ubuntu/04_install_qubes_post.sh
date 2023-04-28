#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$DEBUG" == "1" ]; then
    set -x
fi

# Source external scripts
# shellcheck source=template_ubuntu/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_ubuntu/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

##### '=========================================================================
debug ' Ubuntu post Qubes...'
##### '=========================================================================

#### '-------------------------------------------------------------------------
info ' Cleaning up  any left over files from installation'
#### '-------------------------------------------------------------------------
rm -rf "${INSTALL_DIR}"/etc/apt/sources.list.d/qubes-r?.list
