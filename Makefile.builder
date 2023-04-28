ifneq (,$(findstring $(DIST),stretch buster bullseye bookworm))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := debian
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.debian
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)template_debian
    DIST_TAG := $(strip $(subst stretch, deb9, $(DIST)))
    DIST_TAG := $(strip $(subst buster, deb10, $(DIST_TAG)))
    DIST_TAG := $(strip $(subst bullseye, deb11, $(DIST_TAG)))
    DIST_TAG := $(strip $(subst bookworm, deb12, $(DIST_TAG)))
endif
ifneq (,$(findstring $(DIST),bionic focal jammy))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    TEMPLATE_ENV_WHITELIST += SYSTEMD_NSPAWN_ENABLE
    DISTRIBUTION := ubuntu
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.ubuntu
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)template_ubuntu
    DIST_TAG := $(DIST)
endif

# vim: ft=make
