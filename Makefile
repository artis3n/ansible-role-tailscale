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

# Only run this on GitHub Codespaces in order to set up Python 3.9
.PHONY: codespaces-install
codespaces-install:
	sudo add-apt-repository ppa:deadsnakes/ppa
	sudo apt-get update
	sudo apt-get install python3.9
	sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
	sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
	make install

.PHONY: clean
clean:
	pipenv --rm

.PHONY: test
test:
	ANSIBLE_VAULT_PASSWORD_FILE=$(PWD)/.ci-vault-pass pipenv run molecule test --all

.PHONY: lint
lint:
	pipenv run ansible-lint
