#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# Source external scripts
source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '-------------------------------------------------------------------------
debug ' Installing base system using debootstrap'
##### '-------------------------------------------------------------------------

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" ]; then
    #### "------------------------------------------------------------------
    info " $(templateName): Installing base '${DISTRIBUTION}-${DIST}' system"
    #### "------------------------------------------------------------------
    COMPONENTS="" debootstrap \
        --arch=amd64 \
        --include="ncurses-term locales tasksel" \
        --components=main \
        --keyring="${SCRIPTSDIR}/keys/${DIST}-${DISTRIBUTION}-archive-keyring.gpg" \
        "${DIST}" "${INSTALLDIR}" "${DEBIAN_MIRROR}" || { 
            error "Debootstrap failed!";
            exit 1; 
        }

    #### '----------------------------------------------------------------------
    info ' Configure keyboard'
    #### '----------------------------------------------------------------------
    configureKeyboard

    #### '----------------------------------------------------------------------
    info ' Update locales'
    #### '----------------------------------------------------------------------
    updateLocale

    #### '----------------------------------------------------------------------
    info 'Link mtab'
    #### '----------------------------------------------------------------------
    chroot rm -f /etc/mtab
    chroot ln -s /proc/self/mounts /etc/mtab

    # TMPDIR is set in vars.  /tmp should not be used since it will be cleared
    # if building template with LXC contaniners on a reboot
    mkdir -p "${INSTALLDIR}/${TMPDIR}"

    # Mark section as complete
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap"

    # If SNAPSHOT=1, Create a snapshot of the already debootstraped image
    createSnapshot "debootstrap"
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"
