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

.PHONY: test
test:
	ANSIBLE_VAULT_PASSWORD_FILE=$(PWD)/.ci-vault-pass pipenv run molecule test

.PHONY: lint
lint:
	pipenv run yamllint .
	pipenv run ansible-lint
