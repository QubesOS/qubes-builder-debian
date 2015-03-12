#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# Source external scripts
source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

INSTALLDIR="$(readlink -m mnt)"

# Make sure ${INSTALLDIR} is not mounted
umount_all "${INSTALLDIR}" || true

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

# ==============================================================================
# Use a snapshot of the debootstraped debian image
# ==============================================================================
manage_snapshot() {
    local snapshot="${1}"

    umount_kill "${INSTALLDIR}" || true
    mount -o loop "${IMG}" "${INSTALLDIR}" || exit 1

    # Remove old snapshots if groups completed
    if [ -e "${INSTALLDIR}/${TMPDIR}/.prepared_groups" ]; then
        outputc stout "Removing stale snapshots"
        umount_kill "${INSTALLDIR}" || true
        rm -rf "${debootstrap_snapshot}"
        rm -rf "${packages_snapshot}"
        return
    fi

    outputc stout "Replacing ${IMG} with snapshot ${snapshot}"
    umount_kill "${INSTALLDIR}" || true
    cp -f "${snapshot}" "${IMG}"
}

# ==============================================================================
# Determine if a snapshot should be used, reuse an existing image or
# delete the existing image to start fresh based on configuration options
#
# SNAPSHOT=1 - Use snapshots; Will remove after successful build
# If debootstrap did not complete, the existing image will be deleted
# ==============================================================================
splitPath "${IMG}" path_parts
packages_snapshot="${path_parts[dir]}${path_parts[base]}-packages${path_parts[dotext]}"
debootstrap_snapshot="${path_parts[dir]}${path_parts[base]}-debootstrap${path_parts[dotext]}"

if [ -f "${IMG}" ]; then
    if [ -f "${packages_snapshot}" -a "${SNAPSHOT}" == "1" ]; then
        # Use 'packages' snapshot
        manage_snapshot "${packages_snapshot}"

    elif [ -f "${debootstrap_snapshot}" -a "${SNAPSHOT}" == "1" ]; then
        # Use 'debootstrap' snapshot
        manage_snapshot "${debootstrap_snapshot}"

    else
        # Use '$IMG' if debootstrap did not fail
        mount -o loop "${IMG}" "${INSTALLDIR}" || exit 1

        # Assume a failed debootstrap installation if .prepared_debootstrap does not exist
        if [ -e "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" ]; then
            debug "Reusing existing image ${IMG}"
        else
            outputc stout "Removing stale or incomplete ${IMG}"
            umount_kill "${INSTALLDIR}" || true
            rm -f "${IMG}"
        fi

        # Umount image; don't fail if its already umounted
        umount_kill "${INSTALLDIR}" || true
    fi
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"
