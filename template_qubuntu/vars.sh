#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source ./functions.sh

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
# Location to grab Ubuntu packages
# ------------------------------------------------------------------------------
DEBIAN_MIRRORS=(
    'http://archive.ubuntu.com/ubuntu'
)

# ------------------------------------------------------------------------------
# Kernel package to install
# ------------------------------------------------------------------------------
KERNEL_PACKAGE_NAME="linux-image-generic"

# ------------------------------------------------------------------------------
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS="-o Dpkg::Options::=--force-confnew -o Dpkg::Options::=--force-unsafe-io --yes"
APT_GET_OPTIONS+=" -o Acquire::Retries=3"
if [ -n "$REPO_PROXY" ]; then
     APT_GET_OPTIONS+=" -o Acquire::http::Proxy=${REPO_PROXY}"
     DEBOOTSTRAP_PREFIX+=" env http_proxy=${REPO_PROXY}"
fi


if [ "0${BUILDER_TURBO_MODE}" -gt 0 ]; then
    APT_GET_OPTIONS+=" -o Dpkg::Options::=--force-unsafe-io"
    eatmydata_maybe=eatmydata
fi

containsFlavor 'no-recommends' && {
    APT_GET_OPTIONS+=" -o APT::Install-Recommends=0  -o APT::Install-Suggests=0" 
} || true
