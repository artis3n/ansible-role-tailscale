#!/usr/bin/env make

.PHONY: all
all: lint test

# Install Python 3.10 first
.PHONY: install
install:
	poetry install
	poetry run pre-commit install --install-hooks

.PHONY: clean
clean:
	poetry env remove

.PHONY: update
update:
	poetry update
	poetry run pre-commit autoupdate

# If local, make sure TAILSCALE_CI_KEY env var is set.
# This is automatically populated in a GitHub Codespace.
.PHONY: test
test:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	poetry run molecule test --all
endif

.PHONY: lint
lint:
	poetry run yamllint .
	poetry run ansible-lint
