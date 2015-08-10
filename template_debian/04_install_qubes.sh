#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '-------------------------------------------------------------------------
debug ' Installing Qubes packages'
##### '-------------------------------------------------------------------------

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_groups" "prepared_groups installataion has not completed!... Exiting"

# Create system mount points
prepareChroot

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_qubes" ]; then
    #### '----------------------------------------------------------------------
    info ' Trap ERR and EXIT signals and cleanup (umount)'
    #### '----------------------------------------------------------------------
    trap cleanup ERR
    trap cleanup EXIT

    #### '----------------------------------------------------------------------
    info ' Install Qubes Repo and update'
    #### '----------------------------------------------------------------------
    installQubesRepo
    aptUpdate

    #### '----------------------------------------------------------------------
    info ' Execute any distribution specific flavor or sub flavor'
    #### '----------------------------------------------------------------------
    buildStep "${0}" "${DIST}"

    #### '----------------------------------------------------------------------
    info ' Install Qubes packages listed in packages_qubes.list file(s)'
    #### '----------------------------------------------------------------------
    installPackages packages_qubes.list
    uninstallQubesRepo

    #### '----------------------------------------------------------------------
    info ' Re-update locales'
    ####   (Locales get reset during package installation sometimes)
    #### '----------------------------------------------------------------------
    updateLocale

    #### '----------------------------------------------------------------------
    info ' Cleanup'
    #### '----------------------------------------------------------------------
    umount_all "${INSTALLDIR}/" || true
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_qubes"
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
