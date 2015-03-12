#
# Makefile
#

all:
	@true

# Prompt to confirm import of Whonix keys
.PHONY: import-whonix-keys
import-whonix-keys:
	@if [ "$$WHONIX" == "1" ]; then \
	    export GNUPGHOME="$(SCRIPT_DIR)/keyrings/git"; \
            if ! gpg --list-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA >/dev/null 2>&1; then \
                echo "**********************************************************"; \
                echo "*** You've selected Whonix build, this will import     ***"; \
                echo "*** Whonix code signing key to qubes-builder, globally ***"; \
                echo "**********************************************************"; \
                echo -n "Do you want to continue? (y/N) "; \
                read answer; \
                [ "$$answer" == "y" ] || exit 1; \
                echo '916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA:6:' | gpg --import-ownertrust; \
                gpg --import $(SCRIPT_DIR)/$(SRC_DIR)/builder-debian/keys/whonix-developer-patrick.asc; \
                gpg --list-keys; \
            fi; \
	    touch "$$GNUPGHOME/pubring.gpg"; \
	fi

get-sources:
	@true

import-keys: import-whonix-keys
	@true

verify-sources: import-keys
	@true

