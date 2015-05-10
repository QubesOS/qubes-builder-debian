#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source ./functions.sh

# ==============================================================================
# Global variables and functions
# ==============================================================================

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
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS="-o Dpkg::Options::=--force-confnew -o Dpkg::Options::=--force-unsafe-io --yes"
APT_GET_OPTIONS+=" -o Acquire::Retries=3"

if [ "0${BUILDER_TURBO_MODE}" -gt 0 ]; then
    APT_GET_OPTIONS+=" -o Dpkg::Options::=--force-unsafe-io"
    eatmydata_maybe=eatmydata
fi

containsFlavor 'no-recommends' && {
    APT_GET_OPTIONS+=" -o APT::Install-Recommends=0  -o APT::Install-Suggests=0" 
} || true
