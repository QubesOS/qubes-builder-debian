#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/distribution.sh"

##### '-------------------------------------------------------------------------
debug ' Installing and building Whonix'
##### '-------------------------------------------------------------------------


#### '--------------------------------------------------------------------------
info ' Trap ERR and EXIT signals and cleanup (umount)'
#### '--------------------------------------------------------------------------
trap cleanup ERR
trap cleanup EXIT

if ! [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_prepared_groups" ]; then
    #### '----------------------------------------------------------------------
    info ' Installing extra packages in packages_whonix.list file'
    #### '----------------------------------------------------------------------
    installPackages packages_whonix.list
    touch "${INSTALLDIR}/${TMPDIR}/.whonix_prepared_groups"
fi


# ------------------------------------------------------------------------------
# chroot Whonix build script
# ------------------------------------------------------------------------------
read -r -d '' WHONIX_BUILD_SCRIPT <<'EOF' || true
################################################################################
# Pre Fixups
sudo mkdir -p /boot/grub2
sudo touch /boot/grub2/grub.cfg
sudo mkdir -p /boot/grub
sudo touch /boot/grub/grub.cfg
sudo mkdir --parents --mode=g+rw "/tmp/uwt"

# Whonix seems to re-install sysvinit even though there is a hold
# on the package.  Things seem to work anyway. BUT hopfully the
# hold on grub* don't get removed
sudo apt-mark hold sysvinit
sudo apt-mark hold grub-pc grub-pc-bin grub-common grub2-common

# Whonix expects haveged to be started
sudo /etc/init.d/haveged start
################################################################################
# Whonix installation
export WHONIX_BUILD_UNATTENDED_PKG_INSTALL="1"

pushd ~/Whonix
sudo ~/Whonix/whonix_build \
    --build $1 \
    --64bit-linux \
    --current-sources \
    --enable-whonix-apt-repository \
    --whonix-apt-repository-distribution $2 \
    --install-to-root \
    --skip-verifiable \
    --minimal-report \
    --skip-sanity-tests || { exit 1; }
popd
EOF


##### '-------------------------------------------------------------------------
debug ' Preparing Whonix for installation'
##### '-------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_prepared_groups" ] && ! [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_prepared" ]; then
    info "Preparing Whonix system"

    #### '----------------------------------------------------------------------
    info ' Initializing Whonix submodules'
    #### '----------------------------------------------------------------------
    pushd "${WHONIX_DIR}"
    {
        git add Makefile || true
        git commit Makefile -m 'Added Makefile' || true
        su $(logname) -c "git submodule update --init --recursive";
    }
    popd

    #### '----------------------------------------------------------------------
    info ' Faking grub installation since Whonix has depends on grub-pc'
    #### '----------------------------------------------------------------------
    mkdir -p "${INSTALLDIR}/boot/grub"
    cp "${INSTALLDIR}/usr/lib/grub/i386-pc/"* "${INSTALLDIR}/boot/grub"
    rm -f "${INSTALLDIR}/usr/sbin/update-grub"
    chroot ln -s /bin/true /usr/sbin/update-grub

    #### '----------------------------------------------------------------------
    info ' Adding a user account for Whonix to build with'
    #### '----------------------------------------------------------------------
    chroot id -u 'user' >/dev/null 2>&1 || \
    {
        # UID needs match host user to have access to Whonix sources
        chroot groupadd -f user
        [ -n "$SUDO_UID" ] && USER_OPTS="-u $SUDO_UID"
        chroot useradd -g user $USER_OPTS -G sudo,audio -m -s /bin/bash user
        if [ `chroot id -u user` != 1000 ]; then
            chroot useradd -g user -u 1000 -M -s /bin/bash user-placeholder
        fi
    }

    #### '----------------------------------------------------------------------
    info ' Installing Whonix build scripts'
    #### '----------------------------------------------------------------------
    echo "${WHONIX_BUILD_SCRIPT}" > "${INSTALLDIR}/home/user/whonix_build.sh"
    chmod 0755 "${INSTALLDIR}/home/user/whonix_build.sh"

    #### '----------------------------------------------------------------------
    info ' Removing apt-listchanges if it exists,so no prompts appear'
    #### '----------------------------------------------------------------------
    #      Whonix does not handle this properly, but aptInstall packages will
    aptRemove apt-listchanges || true

    #### '----------------------------------------------------------------------
    info ' Copying additional files required for build'
    #### '----------------------------------------------------------------------
    copyTree "files"

    touch "${INSTALLDIR}/${TMPDIR}/.whonix_prepared"
fi


##### '-------------------------------------------------------------------------
debug ' Installing Whonix code base'
##### '-------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_prepared" ] && ! [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_installed" ]; then
    if ! [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        chroot su user -c 'mkdir /home/user/Whonix'
    fi

    mount --bind "../Whonix" "${INSTALLDIR}/home/user/Whonix"

    if [ "${TEMPLATE_FLAVOR}" == "whonix-gateway" ]; then
        BUILD_TYPE="--torgateway"
    elif [ "${TEMPLATE_FLAVOR}" == "whonix-workstation" ]; then
        BUILD_TYPE="--torworkstation"
    else
        error "Incorrent Whonix type \"${TEMPLATE_FLAVOR}\" selected.  Not building Whonix modules"
        error "You need to set TEMPLATE_FLAVOR environment variable to either"
        error "whonix-gateway OR whonix-workstation"
        exit 1
    fi

    # Whonix needs /dev/pts mounted during build
    mount --bind /dev "${INSTALLDIR}/dev"
    mount --bind /dev/pts "${INSTALLDIR}/dev/pts"

    chroot su user -c "cd ~; ./whonix_build.sh ${BUILD_TYPE} ${DIST}" || { exit 1; }

    touch "${INSTALLDIR}/${TMPDIR}/.whonix_installed"
fi


##### '-------------------------------------------------------------------------
debug ' Whonix Post Installation Configurations'
##### '-------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_installed" ] && ! [ -f "${INSTALLDIR}/${TMPDIR}/.whonix_post" ]; then

    #### '----------------------------------------------------------------------
    info ' Restoring original network interfaces'
    #### '----------------------------------------------------------------------
    pushd "${INSTALLDIR}/etc/network"
    {
        rm -f interfaces;
        ln -s interfaces.backup interfaces;
    }
    popd

    #### '----------------------------------------------------------------------
    info ' Temporarily retore original resolv.conf for remainder of install process'
    info ' (Will be restored back in wheezy+whonix/04_qubes_install_post.sh)'
    #### '----------------------------------------------------------------------
    pushd "${INSTALLDIR}/etc"
    {
        rm -f resolv.conf;
        cp -p resolv.conf.backup resolv.conf;
    }
    popd

    #### '----------------------------------------------------------------------
    info ' Temporarily retore original hosts for remainder of install process'
    info ' (Will be restored on initial boot)'
    #### '----------------------------------------------------------------------
    pushd "${INSTALLDIR}/etc"
    {
        rm -f hosts;
        cp -p hosts.anondist-orig hosts;
    }
    popd

    #### '----------------------------------------------------------------------
    info ' Restore default user UID set to so same in all builds regardless of build host'
    #### '----------------------------------------------------------------------
    if [ -n "`chroot id -u user-placeholder`" ]; then
        chroot userdel user-placeholder
        chroot usermod -u 1000 user
    fi

    #### '----------------------------------------------------------------------
    info ' Enable some aliases in .bashrc'
    #### '----------------------------------------------------------------------
    sed -i "s/^# export/export/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# eval/eval/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# alias/alias/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^#force_color_prompt/force_color_prompt/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/#alias/alias/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/alias l='ls -CF'/alias l='ls -l'/g" "${INSTALLDIR}/home/user/.bashrc"

    #### '----------------------------------------------------------------------
    info ' Remove apt-cacher-ng'
    #### '----------------------------------------------------------------------
    chroot service apt-cacher-ng stop || :
    chroot update-rc.d apt-cacher-ng disable || :
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot apt-get.anondist-orig -y --force-yes remove --purge apt-cacher-ng

    #### '----------------------------------------------------------------------
    info ' Remove original sources.list (Whonix copied them to .../debian.list)'
    #### '----------------------------------------------------------------------
    rm -f "${INSTALLDIR}/etc/apt/sources.list"

    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot apt-get.anondist-orig update

    touch "${INSTALLDIR}/${TMPDIR}/.whonix_post"
fi


##### '-------------------------------------------------------------------------
debug ' Temporarily retore original apt-get for remainder of install process'
##### '-------------------------------------------------------------------------
pushd "${INSTALLDIR}/usr/bin" 
{
    rm -f apt-get;
    cp -p apt-get.anondist-orig apt-get;
}
popd

#### '----------------------------------------------------------------------
info ' Cleanup'
#### '----------------------------------------------------------------------
trap - ERR EXIT
trap
