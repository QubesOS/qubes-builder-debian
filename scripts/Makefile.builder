#
# Generic Makefile.builder for Debian quilt packages
#

ifeq ($(PACKAGE_SET),vm)
  ifneq ($(filter $(DISTRIBUTION), debian qubuntu),)
    DEBIAN_BUILD_DIRS := debian
    SOURCE_COPY_IN := source-debian-quilt-copy-in
  endif
endif

all: 
	@true

install:
	find . -maxdepth 1 -type d ! -path "./debian" -a ! -path "./deb" -a ! -path "./.git" -a ! -path "." -exec cp -a '{}' $$DESTDIR \;

source-debian-quilt-copy-in: VERSION = $(shell $(DEBIAN_PARSER) changelog --package-version $(ORIG_SRC)/$(DEBIAN_BUILD_DIRS)/changelog)
source-debian-quilt-copy-in: NAME = $(shell $(DEBIAN_PARSER) changelog --package-name $(ORIG_SRC)/$(DEBIAN_BUILD_DIRS)/changelog)
source-debian-quilt-copy-in: ORIG_FILE = "$(CHROOT_DIR)/$(DIST_SRC)/../$(NAME)_$(VERSION).orig.tar.gz"
source-debian-quilt-copy-in:
	cd $(CHROOT_DIR)/$(DIST_SRC); \
	rm -f Makefile; \
	ln -sf Makefile.builder Makefile
	-$(shell $(ORIG_SRC)/debian-quilt $(ORIG_SRC)/series-debian-vm.conf $(CHROOT_DIR)/$(DIST_SRC)/debian/patches)
	tar cfz $(ORIG_FILE) --exclude-vcs --exclude=rpm --exclude=pkgs --exclude=deb --exclude=debian -C $(CHROOT_DIR)/$(DIST_SRC) .

# vim: filetype=make
