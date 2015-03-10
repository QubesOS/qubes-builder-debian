#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '--------------------------------------------------------------------------
info 'HACK: Copying utopic sources.list to install systemd'
#### '--------------------------------------------------------------------------
cat > "${INSTALLDIR}/etc/apt/sources.list.d/systemd-utopic.list" <<EOF
deb http://mirror.csclub.uwaterloo.ca/ubuntu/ utopic main
EOF

#### '--------------------------------------------------------------------------
info 'Add universe to sources.list'
#### '--------------------------------------------------------------------------
updateQubuntuSourceList

#### '--------------------------------------------------------------------------
info 'Install Systemd'
#### '--------------------------------------------------------------------------
aptUpdate
installSystemd

#### '--------------------------------------------------------------------------
info 'HACK: Commenting out utopic sources.list used to install systemd'
#### '--------------------------------------------------------------------------
sed -i "s/^deb/#deb/" "${INSTALLDIR}"/etc/apt/sources.list.d/systemd-utopic.list

#### '--------------------------------------------------------------------------
info 'apt-get update'
#### '--------------------------------------------------------------------------
aptUpdate

