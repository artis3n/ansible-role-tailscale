#!/usr/bin/env make

.PHONY: all
all: lint test

# Install Python 3.10 first
.PHONY: install
install:
	if [ ! -d ~/.local/share/virtualenvs/ ]; then mkdir -p ~/.local/share/virtualenvs; fi;
	if [ ! $$(find ~/.local/share/virtualenvs/ -name "artis3n.tailscale*") ]; then pipenv install --dev; fi;
	if [ ! -f .git/hooks/pre-commit ]; then pipenv run pre-commit install; fi;

.PHONY: clean
clean:
	pipenv --rm

.PHONY: update
update:
	pipenv update --dev
	pipenv run pre-commit autoupdate

# If local, make sure TAILSCALE_CI_KEY env var is set.
# This is automatically populated in a GitHub Codespace.
.PHONY: test
test:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	pipenv run molecule test --all
endif

.PHONY: lint
lint:
	pipenv run yamllint .
	pipenv run ansible-lint
