#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source ./functions.sh

# ==============================================================================
# Global variables and functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Temp directory to place installation files and progress markers
# (Do not use /tmp since if built in a real VM, /tmp will be empty on a reboot)
# ------------------------------------------------------------------------------
TMPDIR="/var/lib/qubes-whonix/install"

# ------------------------------------------------------------------------------
# The codename of the debian version to install.
# jessie = testing, wheezy = stable
# ------------------------------------------------------------------------------
DEBIANVERSION=${DIST}

# ------------------------------------------------------------------------------
# Location to grab Debian packages
# ------------------------------------------------------------------------------
DEBIAN_MIRROR=http://ftp.us.debian.org/debian

# TODO: Not yet implemented
DEBIAN_MIRRORS=('http://ftp.us.debian.org/debian',
                'http://http.debian.net/debian,
                'http://ftp.ca.debian.org/debian,
               )

# ------------------------------------------------------------------------------
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS="-o Dpkg::Options::="--force-confnew" --force-yes --yes"
