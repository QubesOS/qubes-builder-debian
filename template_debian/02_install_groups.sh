#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Configuring and Installing packages for ${DIST}"
##### "=========================================================================

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" "prepared_debootstrap installation has not completed!... Exiting"

# Create system mount points
prepareChroot

# Make sure there is a resolv.conf with network of this AppVM for building
createResolvConf

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

# ==============================================================================
# Configure base system and install any additional packages which could
# include +TEMPLATE_FLAVOR such as gnome as set in configuration file
# ==============================================================================
if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_groups" ]; then
    #### '----------------------------------------------------------------------
    info ' Trap ERR and EXIT signals and cleanup (umount)'
    #### '----------------------------------------------------------------------
    trap cleanup ERR
    trap cleanup EXIT

    #### '----------------------------------------------------------------------
    info ' Install standard Debian packages'
    #### '----------------------------------------------------------------------
    containsFlavor "minimal" || {
        if ! [ -f "${INSTALLDIR}/${TMPDIR}/.debian_packages" ]; then
            packages="$(chroot tasksel --new-install --task-packages standard)"
            aptInstall ${packages}
        fi
    }
    touch "${INSTALLDIR}/${TMPDIR}/.debian_packages"

    #### '----------------------------------------------------------------------
    info ' Distribution specific steps (install systemd, add sources, etc)'
    #### '----------------------------------------------------------------------
    buildStep "$0" "${DIST}"

    #### '----------------------------------------------------------------------
    info " Installing extra packages in script_${DIST}/packages.list file"
    #### '----------------------------------------------------------------------
    installPackages
    createSnapshot "packages"
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_packages"

    #### '----------------------------------------------------------------------
    info ' Execute any template flavor or sub flavor scripts after packages are installed'
    #### '----------------------------------------------------------------------
    buildStep "$0" "packages_installed"

    #### '----------------------------------------------------------------------
    info ' apt-get dist-upgrade'
    #### '----------------------------------------------------------------------
    aptDistUpgrade

    #### '----------------------------------------------------------------------
    info ' Cleanup'
    #### '----------------------------------------------------------------------
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_groups"
    trap - ERR EXIT
    trap
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"

# ==============================================================================
# Kill all processes and umount all mounts within ${INSTALLDIR}, but not
# ${INSTALLDIR} itself (extra '/' prevents ${INSTALLDIR} from being umounted)
# ==============================================================================
umount_all "${INSTALLDIR}/" || true
