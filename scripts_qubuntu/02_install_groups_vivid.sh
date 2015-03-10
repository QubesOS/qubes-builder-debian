#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '--------------------------------------------------------------------------
info 'Add universe to sources.list'
#### '--------------------------------------------------------------------------
updateQubuntuSourceList

#### '--------------------------------------------------------------------------
info 'Install Systemd'
#### '--------------------------------------------------------------------------
installSystemd

