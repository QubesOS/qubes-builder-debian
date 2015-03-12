#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '-------------------------------------------------------------------------
debug ' Whonix post installation cleanup'
##### '-------------------------------------------------------------------------


#### '--------------------------------------------------------------------------
info ' Restoring Whonix apt-get'
#### '--------------------------------------------------------------------------
pushd "${INSTALLDIR}/usr/bin" 
{
    rm -f apt-get;
    cp -p apt-get.anondist apt-get;
}
popd

#### '--------------------------------------------------------------------------
info ' Restoring Whonix resolv.conf'
#### '--------------------------------------------------------------------------
pushd "${INSTALLDIR}/etc"
{
    rm -f resolv.conf;
    cp -p resolv.conf.anondist resolv.conf;
}
popd

#### '--------------------------------------------------------------------------
info ' Removing files created during installation that are no longer required'
#### '--------------------------------------------------------------------------
rm -rf "${INSTALLDIR}/home.orig/user/Whonix"
rm -rf "${INSTALLDIR}/home.orig/user/whonix_binary"
rm -f "${INSTALLDIR}/home.orig/user/whonix_fix"
rm -f "${INSTALLDIR}/home.orig/user/whonix_build.sh"
rm -f "${INSTALLDIR}/etc/sudoers.d/whonix-build"
rm -f "${TMPDIR}/etc/sudoers.d/whonix-build"
