#!/usr/bin/env make

.PHONY: all
all: lint test

# Install Python 3.10 first
.PHONY: install
install:
	poetry install --no-root
	poetry run pre-commit install --install-hooks
	poetry run ansible-galaxy collection install -r requirements.yml

.PHONY: clean
clean:
	poetry env remove

.PHONY: update
update:
	poetry update
	poetry run pre-commit autoupdate

.PHONY: lint
lint:
	poetry run ansible-lint --profile=production

.PHONY: test
test: test-default test-absent

# If local, make sure TAILSCALE_CI_KEY env var is set.
# This is automatically populated in a GitHub Codespace.
.PHONY: test-all
test-all:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --all
endif

.PHONY: test-default
test-default:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name default
endif

.PHONY: test-idempotent-up
test-idempotent-up:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name idempotent-up
endif

.PHONY: test-args
test-args:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name args
endif

.PHONY: test-absent
test-absent:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name state-absent
endif

.PHONY: test-oauth
test-oauth:
ifndef TAILSCALE_OAUTH_CLIENT_SECRET
	$(error TAILSCALE_OAUTH_CLIENT_SECRET is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name oauth
endif

.PHONY: test-strategy-free
test-strategy-free:
ifndef TAILSCALE_CI_KEY
	$(error TAILSCALE_CI_KEY is not set)
else
	HEADSCALE_IMAGE=headscale/headscale:0.22 poetry run molecule test --scenario-name strategy-free
endif

.PHONY: test-headscale
test-headscale:
	HEADSCALE_IMAGE=headscale/headscale:0.22 USE_HEADSCALE=true poetry run molecule test --scenario-name default
