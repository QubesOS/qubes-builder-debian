#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

if [ "$VERBOSE" -ge 2 -o "$DEBUG" == "1" ]; then
    set -x
fi

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### "=========================================================================
debug " Installing custom packages and customizing ${DIST}"
##### "=========================================================================

#### '--------------------------------------------------------------------------
info ' Adding contrib, non-free and Debian security to repository.'
#### '--------------------------------------------------------------------------
updateDebianSourceList

#### '----------------------------------------------------------------------
info ' Adding wheezy backports repository.'
#### '----------------------------------------------------------------------
mirror="$(cat ${INSTALLDIR}/${TMPDIR}/.mirror)"
source="deb ${mirror} wheezy-backports main"
if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
    touch "${INSTALLDIR}/etc/apt/sources.list"
    echo -e "$source\n" >> "${INSTALLDIR}/etc/apt/sources.list"
fi
aptUpdate

##### '=========================================================================
debug ' Replace sysvinit with systemd'
##### '=========================================================================

#### '----------------------------------------------------------------------
info ' Remove sysvinit'
#### '----------------------------------------------------------------------
echo 'Yes, do as I say!' | aptRemove sysvinit

#### '----------------------------------------------------------------------
info ' Preventing sysvinit re-installation'
#### '----------------------------------------------------------------------
chroot apt-mark hold sysvinit

#### '----------------------------------------------------------------------
info ' Pin sysvinit to prevent being re-installed'
#### '----------------------------------------------------------------------
cat > "${INSTALLDIR}/etc/apt/preferences.d/qubes_sysvinit" <<EOF
Package: sysvinit
Pin: version *
Pin-Priority: -100
EOF
chmod 0644 "${INSTALLDIR}/etc/apt/preferences.d/qubes_sysvinit"

#### '----------------------------------------------------------------------
info ' Install Systemd'
#### '----------------------------------------------------------------------
aptUpdate
aptInstall systemd-sysv

#### '----------------------------------------------------------------------
info ' Set multu-user.target as the default target (runlevel 3)'
#### '----------------------------------------------------------------------
chroot rm -f /etc/systemd/system/default.target
chroot ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target


# ==============================================================================
# Install backports
#
# NOTE: This needs to be done after systemd has been installed or risk backport
#       being un-installed
# ==============================================================================

#### '----------------------------------------------------------------------
info ' Installing init-system-helpers'
#### '----------------------------------------------------------------------
aptUpdate
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    chroot apt-get ${APT_GET_OPTIONS} -t wheezy-backports install init-system-helpers

#### '----------------------------------------------------------------------
info ' Installing pulseaudo backport'
#### '----------------------------------------------------------------------

# /usr/lib/pulse-4.0/modules/
# start-pulseaudio-with-vchan

#DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
#    chroot apt-get ${APT_GET_OPTIONS} -t wheezy-backports install pulseaudio \
#                                                                  libpulse0 \
#                                                                  pulseaudio-utils \
#                                                                  libpulse-mainloop-glib0 \
#                                                                  pulseaudio-module-x11
