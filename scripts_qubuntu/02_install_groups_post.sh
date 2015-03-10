#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

#### '-------------------------------------------------------------------------
info ' Installing pulseaudio 5'
#### '-------------------------------------------------------------------------
chroot add-apt-repository -y ppa:ubuntu-audio-dev/pulse-testing
aptUpdate
aptInstall pulseaudio
