#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

#
# Handle legacy builder
#

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    TEMPLATE_SCRIPTS_DIR="$(readlink -f .)"
    PACKAGES_DIR="${PWD}/pkgs-for-template/${DIST}"
    KEYS_DIR="$SCRIPTSDIR/../keys"
fi

# shellcheck disable=SC1091
source "${TEMPLATE_SCRIPTS_DIR}/functions.sh" >/dev/null
# shellcheck disable=SC1091
source "${TEMPLATE_SCRIPTS_DIR}/umount-kill" >/dev/null

output "INFO: ${TEMPLATE_CONTENT_DIR}/distribution.sh imported by: ${0}"

# ==============================================================================
# Cleanup function
# ==============================================================================
function cleanup() {
    errval=$?
    trap - ERR EXIT
    trap
    error "${1:-"${0}: Error.  Cleaning up and un-mounting any existing mounts"}"
    umount_all "${INSTALL_DIR}" || true

    exit $errval
}

# ==============================================================================
# If .prepared_debootstrap has not been completed, don't continue
# ==============================================================================
function exitOnNoFile() {
    file="${1}"
    message="${2}"

    if ! [ -f "${file}" ]; then
        error "${message}"
        umount_all "${INSTALL_DIR}" || true
        exit 1
    fi
}

# ==============================================================================
# Umount everything within INSTALL_DIR or $1 but kill all processes within first
# ==============================================================================
function umount_all() {
    directory="${1:-"${INSTALL_DIR}"}"

    # Only remove dirvert policies, etc if base INSTALL_DIR mount is being umounted
    if [ "${directory}" == "${INSTALL_DIR}" ] || [ "${directory}" == "${INSTALL_DIR}/" ]; then
        if [ -n "$(mountPoints "$directory")" ]; then
            removeDbusUuid
            removeDivertPolicy
        fi
    fi

    umount_kill "${directory}" || true
}

# ==============================================================================
# Create snapshot
# ==============================================================================
function createSnapshot() {
    snapshot_name="${1}"

    if [ "${SNAPSHOT}" == "1" ]; then
        local path_parts
        splitPath "${IMG}" path_parts
        snapshot_path="${path_parts[dir]}${path_parts[base]}-${snapshot_name}${path_parts[dotext]}"

        # create snapshot
        info "Creating snapshot of ${IMG} to ${snapshot_path}"
        sync
        cp -f "${IMG}" "${snapshot_path}"
    fi
}

# ==============================================================================
# Create DBUS uuid
# ==============================================================================
function createDbusUuid() {
    output "Creating DBUS uuid..."
    removeDbusUuid
    if [ -e "${INSTALL_DIR}/bin/dbus-uuidgen" ]; then
        chroot_cmd dbus-uuidgen --ensure 1>/dev/null 2>&1
    fi
}

# ==============================================================================
# Remove DBUS uuid
# ==============================================================================
function removeDbusUuid() {
    if [ -e "${INSTALL_DIR}"/var/lib/dbus/machine-id ]; then
        output "Removing generated machine uuid..."
        rm "${INSTALL_DIR}/var/lib/dbus/machine-id"
    fi
}

# ==============================================================================
# Set up a temporary dpkg-divert policy to prevent apt from starting services
# on package installation
# ==============================================================================
function addDivertPolicy() {
    output "Deactivating initctl..."
    chroot_cmd dpkg-divert --local --rename --add /sbin/initctl || true

    output "Creating policy-rc.d"
    echo exit 101 > "${INSTALL_DIR}/usr/sbin/policy-rc.d"
    chmod +x "${INSTALL_DIR}/usr/sbin/policy-rc.d"

    # utopic systemd install still broken...
    output "Hacking invoke-rc.d to ignore missing init scripts..."
    chroot_cmd sed -i -e "s/exit 100/exit 0 #exit 100/" /usr/sbin/invoke-rc.d
}

# ==============================================================================
# Remove temporary dpkg-divert policy
# ==============================================================================
function removeDivertPolicy() {
    output "Reactivating initctl..."
    chroot_cmd dpkg-divert --local --rename --remove /sbin/initctl || true

    output "Removing policy-rc.d"
    rm -f "${INSTALL_DIR}/usr/sbin/policy-rc.d"

    output "Restoring invoke-rc.d..."
    chroot_cmd sed -i -e "s/exit 0 #exit 100/exit 100/" /usr/sbin/invoke-rc.d
}

# ==============================================================================
# Create system mount points
# ==============================================================================
function prepareChroot() {
    if ! mountpoint -q "${INSTALL_DIR}/run"; then
        mount -t tmpfs none "${INSTALL_DIR}/run"
    fi
    if ! mountpoint -q "${INSTALL_DIR}/proc"; then
        mount -t proc proc "${INSTALL_DIR}/proc"
    fi
    if ! mountpoint -q "${INSTALL_DIR}/sys"; then
        mount -t sysfs sys "${INSTALL_DIR}/sys"
    fi
    createDbusUuid
    addDivertPolicy
}

# ==============================================================================
# apt-get upgrade
# ==============================================================================
function aptUpgrade() {
    aptUpdate
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" --download-only upgrade -u -y
    find "${INSTALL_DIR}/var/cache/apt/archives" -name '*.deb' -print0 |\
        xargs -0r sha256sum
    # shellcheck disable=2086,2154
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot_cmd env APT_LISTCHANGES_FRONTEND=none $eatmydata_maybe \
            apt-get "${APT_GET_OPTIONS[@]}" upgrade -u -y
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" clean
}

# ==============================================================================
# apt-get dist-upgrade
# ==============================================================================
function aptDistUpgrade() {
    aptUpdate
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" --download-only dist-upgrade -u -y
    find "${INSTALL_DIR}/var/cache/apt/archives" -name '*.deb' -print0 |\
        xargs -0r sha256sum
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot_cmd env APT_LISTCHANGES_FRONTEND=none $eatmydata_maybe \
            apt-get "${APT_GET_OPTIONS[@]}" dist-upgrade -u -y
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" clean
}

# ==============================================================================
# apt-get update
# ==============================================================================
function aptUpdate() {
    debug "Updating system"
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" update
    # check for CVE-2016-1252 - directly after debootstrap, still vulnerable
    # apt is installed
    wc -L "${INSTALL_DIR}/var/lib/apt/lists/"*InRelease | awk '$1 > 1024 {print; exit 1}'
}

# ==============================================================================
# apt-get remove
# ==============================================================================
function aptRemove() {
    read -r -a files <<<"$@"
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot_cmd $eatmydata_maybe apt-get "${APT_GET_OPTIONS[@]}" --force-yes remove "${files[@]}"
}

# ==============================================================================
# apt-get install
# ==============================================================================
function aptInstall() {
    read -r -a files <<<"$@"
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" --download-only install "${files[@]}"
    find "${INSTALL_DIR}/var/cache/apt/archives" -name '*.deb' -print0 |\
        xargs -0r sha256sum
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND="noninteractive" DEBIAN_PRIORITY="critical" DEBCONF_NOWARNINGS="yes" \
        chroot_cmd $eatmydata_maybe apt-get "${APT_GET_OPTIONS[@]}" install "${files[@]}"
    retcode=$?
    chroot_cmd apt-get "${APT_GET_OPTIONS[@]}" clean
    return $retcode
}

# ==============================================================================
# Install extra packages in script_${DIST_CODENAME}/packages.list file
# -and / or- TEMPLATE_FLAVOR directories
# ==============================================================================
function installPackages() {
    local packages_list_name="${1:-packages.list}"

    if containsFlavor "minimal"; then
        getFileLocations packages_list "${packages_list_name}" "${DIST_CODENAME}_minimal"
        if [ -z "${packages_list}" ]; then
            getFileLocations packages_list "${packages_list_name}" "minimal"
        fi
        if [ -z "${packages_list}" ]; then
            getFileLocations packages_list "${packages_list_name}" "${DIST_CODENAME}"
        fi
    elif [ -n "$TEMPLATE_FLAVOR" ]; then
        getFileLocations packages_list "${packages_list_name}" "${DIST_CODENAME}_${TEMPLATE_FLAVOR}"
        if [ -z "${packages_list}" ]; then
            getFileLocations packages_list "${packages_list_name}" "${TEMPLATE_FLAVOR}"
        fi
        if [ -z "${packages_list}" ]; then
            getFileLocations packages_list "${packages_list_name}" "${DIST_CODENAME}"
        fi
    else
        getFileLocations packages_list "${packages_list_name}" "${DIST_CODENAME}"
    fi
    if [ -z "${packages_list}" ]; then
        getFileLocations packages_list "${packages_list_name}" ""
    fi

    if [ -z "${packages_list}" ]; then
        error "Can not locate a package.list file!"
        umount_all "${INSTALL_DIR}" || true
        exit 1
    fi

    for package_list in "${packages_list[@]}"; do
        debug "Installing extra packages from: ${package_list}"
        declare -a packages
        readarray -t packages <<< "$(sed '/^ *#/d; s/  *#.*//' "${package_list}" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

        info "Packages: ${packages[*]}"
        aptInstall "${packages[@]}"
    done
}

# ==============================================================================
# Install Systemd
# ==============================================================================
function installSystemd() {
    buildStep "$0" "pre-systemd"
    aptUpdate

    aptInstall systemd
    createDbusUuid

    # Set multi-user.target as default target
    chroot_cmd rm -f /etc/systemd/system/default.target
    chroot_cmd ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

    # XXX: TEMP lets see how stuff work with upstart in control for now
    # Boot using systemd
    chroot_cmd rm -f /sbin/init
    chroot_cmd ln -sf /lib/systemd/systemd /sbin/init

    buildStep "$0" "post-systemd"
}

# ==============================================================================
# ------------------------------------------------------------------------------
#                 C O N F I G U R A T I O N   R E L A T E D
# ------------------------------------------------------------------------------
# ==============================================================================

# ==============================================================================
# Update Debian sources.list
# ==============================================================================
function updateDebianSourceList() {
    local list="${INSTALL_DIR}/etc/apt/sources.list"
    local mirror
    mirror="$(cat "${INSTALL_DIR}/${TMPDIR}/.mirror")"
    touch "${list}"

    nonfree=non-free
    if [ "${DIST_CODENAME}" = "bookworm" ] || [ "${DIST_CODENAME}" = "trixie" ]; then
        nonfree=non-free-firmware
    fi

    # Add contrib and non-free component to repository
    sed -i "s/${DIST_CODENAME} main$/${DEBIANVERSION} main contrib $nonfree/g" "${list}"

    # Add main deb-src repository
    source="#deb-src ${mirror} ${DEBIANVERSION} main contrib $nonfree"
    if ! grep -r -q "$source" "${list}"*; then
        echo -e "$source\n" >> "${list}"
    fi

    # Add Debian security repositories
    if [ "${DEBIANVERSION}" == "buster" ] || [ "${DEBIANVERSION}" == "stretch" ]; then
        security_suffix="/updates"
    else
        security_suffix="-security"
    fi
    source="deb https://deb.debian.org/debian-security ${DEBIANVERSION}${security_suffix} main contrib $nonfree"
    if ! grep -r -q "$source" "${list}"*; then
        echo -e "$source" >> "${list}"
    fi
    source="#deb-src https://deb.debian.org/debian-security ${DEBIANVERSION}${security_suffix} main contrib $nonfree"
    if ! grep -r -q "$source" "${list}"*; then
        echo -e "$source\n" >> "${list}"
    fi
    if [ "${DIST_CODENAME}" = "bookworm" ]; then
        # make bookworm-backports available for newer firmware packages,
        # but it needs to be explicitly selected for a package to be installed
        # from there
        source="deb https://deb.debian.org/debian ${DEBIANVERSION}-backports main contrib $nonfree"
        if ! grep -r -q "$source" "${list}"*; then
            echo -e "$source\n" >> "${list}"
        fi

        source="#deb-src https://deb.debian.org/debian ${DEBIANVERSION}-backports main contrib $nonfree"
        if ! grep -r -q "$source" "${list}"*; then
            echo -e "$source\n" >> "${list}"
        fi
    fi
}

# ==============================================================================
# Add to sources.list
# ==============================================================================
function updateQubuntuSourceList() {
    sed -i "s/${DIST_CODENAME} main$/${DIST_CODENAME} main universe multiverse restricted/g" "${INSTALL_DIR}/etc/apt/sources.list"
#    source="deb http://archive.canonical.com/ubuntu ${DIST_CODENAME} partner"
#    if ! grep -r -q "$source" "${INSTALL_DIR}/etc/apt/sources.list"*; then
#        touch "${INSTALL_DIR}/etc/apt/sources.list"
#        echo "$source" >> "${INSTALL_DIR}/etc/apt/sources.list"
#    fi
    source="deb http://archive.ubuntu.com/ubuntu ${DIST_CODENAME}-security main universe multiverse restricted "
    if ! grep -r -q "$source" "${INSTALL_DIR}/etc/apt/sources.list"*; then
        touch "${INSTALL_DIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALL_DIR}/etc/apt/sources.list"
    fi
    source="deb http://archive.ubuntu.com/ubuntu ${DIST_CODENAME}-updates main universe multiverse restricted "
    if ! grep -r -q "$source" "${INSTALL_DIR}/etc/apt/sources.list"*; then
        touch "${INSTALL_DIR}/etc/apt/sources.list"
        echo "$source" >> "${INSTALL_DIR}/etc/apt/sources.list"
    fi
    aptUpdate
}

# ==============================================================================
# Make sure there is a resolv.conf with network of this AppVM for building
# ==============================================================================
function createResolvConf() {
    rm -f "${INSTALL_DIR}/etc/resolv.conf"
    cp /etc/resolv.conf "${INSTALL_DIR}/etc/resolv.conf"
}

# ==============================================================================
# Ensure umask set in /etc/login.defs is used (022)
# ==============================================================================
function configureUmask() {
    echo "session optional pam_umask.so" >> "${INSTALL_DIR}/etc/pam.d/common-session"
}

# ==============================================================================
# Configure keyboard
# ==============================================================================
function configureKeyboard() {
    debug "Setting keyboard layout"
    cat > "${INSTALL_DIR}/tmp/keyboard.conf" <<'EOF'
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/modelcode    string  pc105
keyboard-configuration  keyboard-configuration/layoutcode   string  us
keyboard-configuration  keyboard-configuration/variantcode  string
keyboard-configuration  keyboard-configuration/optionscode  string
EOF
    chroot_cmd debconf-set-selections /tmp/keyboard.conf
}

# ==============================================================================
# Update locale
# ==============================================================================
function updateLocale() {
    debug "Updating locales"
    chroot_cmd sh -c 'printf "\\nen_US.UTF-8 UTF-8" >> /etc/locales.gen'
    chroot_cmd localedef -i en_US -c -f UTF-8 en_US.UTF-8
    chroot_cmd update-locale LANG=en_US.UTF-8
}

# ==============================================================================
# Configure default applications
# ==============================================================================
function setDefaultApplications() {
    debug "Setting default applications"

    # fix default for text/plain - make sure it is not a console app (if
    # possible)
    text_plain_app=$(chroot_cmd xdg-mime query default text/plain)
    if grep -q '^Terminal=[tT]' "${INSTALL_DIR}/usr/share/applications/$text_plain_app"; then
        text_plain_apps=
        # prefer gedit, if installed
        for app in "${INSTALL_DIR}/usr/share/applications/"*gedit*desktop; do
            if [ -r "$app" ]; then
                text_plain_apps="$text_plain_apps$(basename "$app");"
            fi
        done
        # shellcheck disable=SC2013
        for app in $(grep -rl '^MimeType=.*text/plain;' "${INSTALL_DIR}/usr/share/applications" | grep -F -v gedit | LC_ALL=C sort); do
            if ! grep -q '^Terminal=[tT]' "$app"; then
                text_plain_apps="$text_plain_apps$(basename "$app");"
            fi
        done
        if [ -n "$text_plain_apps" ]; then
            mimeapps_file="${INSTALL_DIR}/usr/share/applications/mimeapps.list"
            touch "$mimeapps_file"
            awk -v apps="$text_plain_apps" '
                /^\[/ {
                    if (indefault && !added) {
                        print "text/plain=" apps
                        added=1
                    }
                    indefault=0
                }
                /^\[Default Applications\]/ { indefault=1 }
                /^text\/plain=/ {
                    if (indefault) { print "text/plain=" apps; added=1 }
                    else { print }
                    next
                }
                /./ { print }
                END {
                    if (!added) {
                        if (!indefault) { print "[Default Applications]" }
                        print "text/plain=" apps
                    }
                }
            ' < "$mimeapps_file" > "$mimeapps_file.new" && \
                mv "$mimeapps_file.new" "$mimeapps_file"
        fi
    fi
}


# ==============================================================================
# ------------------------------------------------------------------------------
#           Q U B E S   S P E C I F I C   F U N C T I O N S
# ------------------------------------------------------------------------------
# ==============================================================================

# ==============================================================================
# Install Qubes Repo
# ==============================================================================
installQubesRepo() {
    info "Defining Qubes CUSTOMREPO Location: ${PACKAGES_DIR}"
    export CUSTOMREPO="${PACKAGES_DIR}"

    info "Mounting local qubes_repo"
    mkdir -p "${INSTALL_DIR}/tmp/qubes_repo"
    mount --bind "${CUSTOMREPO}" "${INSTALL_DIR}/tmp/qubes_repo"

    cat > "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb [trusted=yes] file:/tmp/qubes_repo ${DIST_CODENAME} main
EOF
    if [[ -n "$USE_QUBES_REPO_VERSION" &&  ${DIST_NAME} != "ubuntu" ]]; then
        cat >> "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb [arch=amd64] https://deb.qubes-os.org/r${USE_QUBES_REPO_VERSION}/vm ${DIST_CODENAME} main
EOF
        if [ "0$USE_QUBES_REPO_TESTING" -gt 0 ]; then
            cat >> "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb [arch=amd64] https://deb.qubes-os.org/r${USE_QUBES_REPO_VERSION}/vm ${DIST_CODENAME}-testing main
EOF
        fi
        cp "${KEYS_DIR}/qubes-debian-r${USE_QUBES_REPO_VERSION}.asc" "${INSTALL_DIR}/etc/apt/trusted.gpg.d/qubes-builder.asc"
    elif [[ -n "$USE_QUBES_REPO_VERSION" &&  ${DIST_NAME} == "ubuntu" ]] ; then
        cat >> "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb [arch=amd64] https://debu.qubes-os.org/r${USE_QUBES_REPO_VERSION}/vm ${DIST_CODENAME} main
EOF
        if [ "0$USE_QUBES_REPO_TESTING" -gt 0 ]; then
            cat >> "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb [arch=amd64] https://debu.qubes-os.org/r${USE_QUBES_REPO_VERSION}/vm ${DIST_CODENAME}-testing main
EOF
        fi
        cp "${KEYS_DIR}/qubes-ubuntu-r${USE_QUBES_REPO_VERSION}.asc" "${INSTALL_DIR}/etc/apt/trusted.gpg.d/qubes-builder.asc"
    fi
}

# ==============================================================================
# Uninstall Qubes Repo
# ==============================================================================
uninstallQubesRepo() {
    info "Removing Qubes build repo from sources.list.d"

    # Lets not umount; we do that anyway when 04 exits
    umount_kill "${INSTALL_DIR}/tmp/qubes_repo"
    rm -rf "${INSTALL_DIR}/etc/apt/sources.list.d/qubes-builder.list" "${INSTALL_DIR}/etc/apt/trusted.gpg.d/qubes-builder.asc"
}
