# Make file for infrastructure management by ansible
# file: Makefile

SHELL             = bin/wrap
export CALLER     = $@

ENV              ?= dev
LIMIT            ?= all
ANSIBLE_VERSION  ?= 2.9

venv             := .env/$(ENV)-$(ANSIBLE_VERSION)
activate         := source $(venv)/bin/activate

ansible_params   := --inventory "environments/$(ENV)" --limit "$(LIMIT)"
ansible_playbook := $(activate) && ansible-playbook $(ansible_params)
ansible          := $(activate) && ansible $(ansible_params)

pip              := $(activate) && pip

define ANSIBLECFG
# ansible configuration
# file: ansible.cfg

[defaults]
collections_paths = ansible/collections
inventory         = environments/$(ENV)/hosts.yml
playbook_dir      = ansible/playbooks
roles_path        = ansible/roles
endef

export ANSIBLECFG

.ONESHELL:

$(venv):
	@virtualenv $(venv)
	pip install ansible==$(ANSIBLE_VERSION)

.PHONY: ansible.cfg
ansible.cfg:
	@printf "%s\n" "$${ANSIBLECFG}" > $@

.PHONY: clean
clean:
	@rm ansible.cfg

.PHONY: list-inventory
list-inventory:
	@$(activate) && ansible-inventory --inventory "environments/$(ENV)" --list

.PHONY: ping
ping:
	@$(ansible) --module-name $@ all
