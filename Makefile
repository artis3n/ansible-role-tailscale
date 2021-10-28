#!/usr/bin/env make

.PHONY: all
all: install lint test

.PHONY: install
install:
	if [ ! -f /usr/bin/python3 ]; then sudo apt install python3; fi;
	if [ ! -f ~/.local/bin/pipenv ]; then pip3 install pipenv; fi;
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
# This is automatically populated in a Codespace.
.PHONY: test
test:
	pipenv run molecule test --all

.PHONY: lint
lint:
	pipenv run ansible-lint
