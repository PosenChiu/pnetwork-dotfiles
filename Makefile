SHELL := /bin/sh

ifeq ($(shell /usr/bin/uname -m), arm64)
HOMEBREW_PREFIX ?= /opt/homebrew
else
HOMEBREW_PREFIX ?= /usr/local
endif

BREW ?= $(HOMEBREW_PREFIX)/bin/brew
ASDF ?= $(HOMEBREW_PREFIX)/bin/asdf

INIT_BREW ?= eval "$$($(BREW) shellenv)"
INIT_ASDF ?= . "$(HOMEBREW_PREFIX)/opt/asdf/libexec/asdf.sh"


$(HOME)/.tool-versions: $(PWD)/tool-versions
	@ln -sf $^ $@


.PHONY: init
init: $(PWD)/config/*
	@$(foreach FILE, $^, ln -sf $(FILE) $(HOME)/.$(notdir $(FILE));)

.PHONY: clean
clean: $(PWD)/config/*
	@$(foreach FILE, $^, $(RM) $(HOME)/.$(notdir $(FILE));)

.PHONY: install-homebrew
install-homebrew:
	@/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

.PHONY: uninstall-homebrew
uninstall-homebrew:
	@/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

.PHONY: install-brewfile
install-brewfile:
	$(BREW) update
	$(INIT_BREW) && $(BREW) bundle install --force --cleanup
	@chmod -R go-w "$(HOMEBREW_PREFIX)/share"

.PHONY: update-brewfile
update-brewfile:
	$(BREW) update
	$(INIT_BREW) && $(BREW) bundle install --force
	$(INIT_BREW) && $(BREW) bundle dump --force --brews --casks --taps --vscode
	$(BREW) upgrade
	$(BREW) cleanup
	@chmod -R go-w "$(HOMEBREW_PREFIX)/share"

.PHONY: uninstall-brewfile
uninstall-brewfile:
	@set -euo pipefail; \
	BREW_LIST=$$($(BREW) bundle list); \
	if [[ -n "$$BREW_LIST" ]]; then \
		$(BREW) uninstall --force --ignore-dependencies $$BREW_LIST; \
	fi;

.PHONY: install-tool-versions
install-tool-versions: $(HOME)/.tool-versions
	@cut -d' ' -f1 $(HOME)/.tool-versions | xargs -rI{} $(ASDF) plugin add {}
	@cut -d' ' -f1 $(HOME)/.tool-versions | xargs -rI{} $(ASDF) plugin update {}
	@$(INIT_ASDF) && cut -d' ' -f1 $(HOME)/.tool-versions | xargs -rI{} $(ASDF) install {}

.PHONY: uninstall-tool-versions
uninstall-tool-versions: $(HOME)/.tool-versions
	@$(ASDF) plugin list | grep -v '^*$$' | xargs -rI{} $(ASDF) plugin remove {}
	@$(RM) $(HOME)/.tool-versions

.PHONY: install
install: install-homebrew install-brewfile install-tool-versions

.PHONY: update
update: update-brewfile install-tool-versions

.PHONY: uninstall
uninstall: uninstall-tool-versions uninstall-brewfile uninstall-homebrew
