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
# The codename of the debian version to install.
# jessie = testing, wheezy = stable
# ------------------------------------------------------------------------------
DEBIANVERSION=${DIST}

# ------------------------------------------------------------------------------
# Location to grab Debian packages
# ------------------------------------------------------------------------------
DEBIAN_MIRRORS=(
    'http://http.debian.net/debian'
    'http://ftp.us.debian.org/debian'
    'http://ftp.ca.debian.org/debian'
)

# ------------------------------------------------------------------------------
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS="-o Dpkg::Options::="--force-confnew" --force-yes --yes"

containsFlavor 'no-recommends' && {
    APT_GET_OPTIONS+=" -o APT::Install-Recommends=0  -o APT::Install-Suggests=0" 
} || true
