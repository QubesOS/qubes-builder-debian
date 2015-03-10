#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '=========================================================================
debug ' Ubuntu post Qubes...'
##### '=========================================================================

#### '-------------------------------------------------------------------------
info ' Cleaning up  any left over files from installation'
#### '-------------------------------------------------------------------------
rm -rf "${INSTALLDIR}"/etc/apt/sources.list.d/qubes-r?.list
