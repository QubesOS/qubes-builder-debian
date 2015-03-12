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

# Location to grab ubuntu packages
DEBIAN_MIRROR=http://archive.ubuntu.com/ubuntu

# ------------------------------------------------------------------------------
# Location to grab Ubuntu packages
# ------------------------------------------------------------------------------
DEBIAN_MIRROR=http://archive.ubuntu.com/ubuntu

# TODO: Not yet implemented
DEBIAN_MIRRORS=('http://archive.ubuntu.com/ubuntu',
		       )

# ------------------------------------------------------------------------------
# apt-get configuration options
# ------------------------------------------------------------------------------
APT_GET_OPTIONS="-o Dpkg::Options::="--force-confnew" --force-yes --yes"
