# Makefile-based infrastructure management with Ansible.
# file: Makefile

# changed from bin/wrap back to bash,
# as I need to figure out autocompletion for dynamic targets
SHELL             = bash
export CALLER     = $@

ENV              ?= dev
LIMIT            ?= all
ANSIBLE_VERSION  ?= 5.9

venv             := .env/$(ENV)-$(ANSIBLE_VERSION)
activate         := source $(venv)/bin/activate

ansible_env       = --inventory "environments/$(ENV)"
ansible_limit     = --limit "$(LIMIT)"
ansible_playbook := $(activate) && ansible-playbook $(ansible_env) $(ansible_limit)
ansible          := $(activate) && ansible $(ansible_env)

pip              := $(activate) && pip

find_depth       := -mindepth 1 -maxdepth 1
find_yml         := -type f -name "*.yml" -exec basename {}
playbook_dir     := ansible/playbooks
playbooks        := $(shell find $(playbook_dir) $(find_depth) $(find_yml) \;)

define ANSIBLECFG
# ansible configuration
# file: ansible.cfg

[defaults]
collections_paths = ansible/collections
inventory         = environments/$(ENV)
playbook_dir      = $(playbook_dir)
roles_path        = ansible/roles
endef

export ANSIBLECFG

define REQUIREMENTSTXT
# pip requirements file
# file: requirements.txt

ansible==$(ANSIBLE_VERSION).*
endef

export REQUIREMENTSTXT

#.ONESHELL:

.PHONY: $(playbooks)
$(playbooks):
	$(ansible_playbook) $(playbook_dir)/$@

$(venv):
	virtualenv $(venv)
	$(pip) install --upgrade pip
	$(pip) install -r requirements.txt

.PHONY: ansible.cfg
ansible.cfg:
	printf "%s\n" "$${ANSIBLECFG}" > $@

.PHONY: clean-cfg
clean-cfg:
	rm ansible.cfg requirements.txt

.PHONY: clean
clean: clean-cfg
	rm -rf ./.env

.PHONY: distclean
distclean: clean
	rm -rf ./dist/*

.PHONY: init
init: $(venv) ansible.cfg requirements.txt

.PHONY: list-inventory
list-inventory: ansible.cfg
	$(activate) && ansible-inventory --list

.PHONY: ping
ping: ansible.cfg
	$(ansible) --module-name $@ $(LIMIT)

.PHONY: requirements
requirements: init
	$(pip) install -r $@.txt

.PHONY: requirements.txt
requirements.txt:
	printf "%s\n" "$${REQUIREMENTSTXT}" > $@

.PHONY: upgrade
upgrade: init
	$(pip) install --$@ pip
	$(pip) install --$@ -r requirements.txt
