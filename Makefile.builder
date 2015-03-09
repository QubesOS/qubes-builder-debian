ifneq (,$(findstring $(DIST),wheezy jessie))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := debian
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.debian
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)scripts_debian
endif
ifneq (,$(findstring $(DIST),trusty utopic vivid))
    DEBIAN_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := qubuntu
    BUILDER_MAKEFILE = $(DEBIAN_PLUGIN_DIR)Makefile.qubuntu
    TEMPLATE_SCRIPTS = $(DEBIAN_PLUGIN_DIR)scripts_qbuntu
endif

# vim: ft=make
