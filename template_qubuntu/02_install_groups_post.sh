#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

if  [ $DIST != "trusty" ]; then
#### '-------------------------------------------------------------------------
info ' Installing pulseaudio 5'
#### '-------------------------------------------------------------------------
chroot_cmd add-apt-repository -y ppa:ubuntu-audio-dev/pulse-testing
aptUpdate
aptInstall pulseaudio
fi
