#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck disable=SC2034

#
# Handle legacy builder
#

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    TEMPLATE_SCRIPTS_DIR="$(readlink -f .)"
    KEYS_DIR="$SCRIPTSDIR/../keys"
    DIST_CODENAME="$DIST"
    DIST_NAME="$DISTRIBUTION"
    PACKAGES_DIR="$BUILDER_REPO_DIR"
    # shellcheck disable=SC2153
    INSTALL_DIR="${INSTALLDIR}"
fi

# shellcheck disable=SC1091
source "${TEMPLATE_SCRIPTS_DIR}/functions.sh" >/dev/null

# ==============================================================================
# Global variables and functions
# ==============================================================================

# when building on Fedora, /bin and /sbin isn't included in PATH...
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ------------------------------------------------------------------------------
# Temp directory to place installation files and progress markers
# ------------------------------------------------------------------------------
TMPDIR="/tmp"

# ------------------------------------------------------------------------------
# The codename of the debian version to install.
# jessie = testing, wheezy = stable
# ------------------------------------------------------------------------------
DEBIANVERSION=${DIST_CODENAME}

# ------------------------------------------------------------------------------
# Location to grab Debian packages
# ------------------------------------------------------------------------------
DEFAULT_DEBIAN_MIRRORS=(
    'https://deb.debian.org/debian'
    'http://deb.debian.org/debian'
    'http://ftp.us.debian.org/debian'
    'http://ftp.ca.debian.org/debian'
)

# DEBIAN_MIRRORS can be set in configuration file to override the defaults
if [ -z "${DEBIAN_MIRRORS}" ]; then
    read -r -a DEBIAN_MIRRORS<<<"${DEFAULT_DEBIAN_MIRRORS[@]}"
fi

# ------------------------------------------------------------------------------
# Kernel package to install
# ------------------------------------------------------------------------------
KERNEL_PACKAGE_NAME="linux-image-amd64"

# ------------------------------------------------------------------------------
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS=("-o" "Dpkg::Options::=--force-confnew" "--yes")
APT_GET_OPTIONS+=("-o" "Acquire::Retries=3")
APT_GET_OPTIONS+=("-o" "Acquire::Language=none")
APT_GET_OPTIONS+=("-o" "Acquire::IndexTargets::deb::Contents-deb::DefaultEnabled=false")
APT_GET_OPTIONS+=("-o" "APT::Update::Error-Mode=any")

if [ "0${BUILDER_TURBO_MODE}" -gt 0 ]; then
    APT_GET_OPTIONS+=("-o" "Dpkg::Options::=--force-unsafe-io")
    eatmydata_maybe=eatmydata
fi

if [ -n "$REPO_PROXY" ]; then
    APT_GET_OPTIONS+=("-o" "Acquire::http::Proxy=${REPO_PROXY}")
    DEBOOTSTRAP_PREFIX+=("env" "http_proxy=${REPO_PROXY}")
    DEBOOTSTRAP_PREFIX+=("env" "https_proxy=${REPO_PROXY}")
fi

if containsFlavor 'no-recommends'; then
    APT_GET_OPTIONS+=("-o" "APT::Install-Recommends=0" "-o" "APT::Install-Suggests=0")
fi
