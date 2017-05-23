ifneq (,$(findstring $(DIST),wheezy jessie stretch))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := debian
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.debian
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)template_debian
    DIST_TAG := $(strip $(subst wheezy, deb7, $(DIST)))
    DIST_TAG := $(strip $(subst jessie, deb8, $(DIST_TAG)))
    DIST_TAG := $(strip $(subst stretch, deb9, $(DIST_TAG)))
endif
ifneq (,$(findstring $(DIST),trusty xenial zesty))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := qubuntu
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.qubuntu
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)template_qubuntu
    DIST_TAG := $(DIST)
endif

# vim: ft=make
