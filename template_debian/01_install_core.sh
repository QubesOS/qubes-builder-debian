#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

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


bootstrap() {
    for mirror in ${DEBIAN_MIRRORS[@]}; do
        if [ ! -d "${INSTALLDIR}/${TMPDIR}" ]; then
            mkdir -m 1777 -p "${INSTALLDIR}/${TMPDIR}"
        fi
        rm -rf "${INSTALLDIR}/${TMPDIR}/dummy-repo"
        mkdir -p "${INSTALLDIR}/${TMPDIR}/dummy-repo/dists/${DIST}"
        echo ${mirror} > "${INSTALLDIR}/${TMPDIR}/.mirror"

        # Download packages first, and log hash of them _before_ installing
        # them. Needs to copy Release{,.gpg} to a dummy _local_ repo, because
        # debootstrap insists on downloading it each time but we want to be sure to use
        # packages downloaded earlier (and logged)
        COMPONENTS="" $DEBOOTSTRAP_PREFIX debootstrap \
            --arch=amd64 \
            --include="ncurses-term,locales,tasksel,$eatmydata_maybe" \
            --components=main \
            --download-only \
            --keyring="${SCRIPTSDIR}/../keys/${DIST}-${DISTRIBUTION}-archive-keyring.gpg" \
            "${DIST}" "${INSTALLDIR}" "${mirror}" && \
        sha256sum "${INSTALLDIR}/var/cache/apt/archives"/*.deb && \
        cp "${INSTALLDIR}/var/lib/apt/lists/debootstrap.invalid_dists_${DIST}_Release" \
            "${INSTALLDIR}/${TMPDIR}/dummy-repo/dists/${DIST}/Release" && \
        cp "${INSTALLDIR}/var/lib/apt/lists/debootstrap.invalid_dists_${DIST}_Release.gpg" \
            "${INSTALLDIR}/${TMPDIR}/dummy-repo/dists/${DIST}/Release.gpg" && \
        COMPONENTS="" $DEBOOTSTRAP_PREFIX debootstrap \
            --arch=amd64 \
            --include="ncurses-term,locales,tasksel,$eatmydata_maybe" \
            --components=main \
            --keyring="${SCRIPTSDIR}/../keys/${DIST}-${DISTRIBUTION}-archive-keyring.gpg" \
            "${DIST}" "${INSTALLDIR}" "file://${INSTALLDIR}/${TMPDIR}/dummy-repo" && \
        return 0
    done
    error "Debootstrap failed!"
    exit 1;
}


if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" ]; then
    #### "------------------------------------------------------------------
    info " $(templateName): Installing base '${DISTRIBUTION}-${DIST}' system"
    #### "------------------------------------------------------------------
    bootstrap || exit 1

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
    chroot_cmd rm -f /etc/mtab
    chroot_cmd ln -s /proc/self/mounts /etc/mtab

    # TMPDIR is set in vars.  /tmp should not be used since it will be cleared
    # if building template with LXC contaniners on a reboot
    mkdir -m 1777 -p "${INSTALLDIR}/${TMPDIR}"

    # Mark section as complete
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap"

    # If SNAPSHOT=1, Create a snapshot of the already debootstraped image
    createSnapshot "debootstrap"
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"
