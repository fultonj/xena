#!/bin/bash

# From
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/post_deployment/tempest/os_tempest.html#installation-on-a-manually-deployed-tripleo-standalone-deployment

INSTALL=1
RUN=1

if [ $INSTALL -eq 1 ]; then
    # pip install tempest
    pushd ~    
    mkdir ~/.ansible/roles -p
    git clone https://opendev.org/openstack/openstack-ansible-os_tempest ~/.ansible/roles/os_tempest
    ansible-galaxy install -r ~/.ansible/roles/os_tempest/requirements.yml --roles-path=~/.ansible/roles/
    popd
fi

if [ $INSTALL -eq 1 ]; then
    export ANSIBLE_ROLES_PATH=$HOME/.ansible/roles
    export ANSIBLE_ACTION_PLUGINS=~/.ansible/roles/config_template/action
    # ansible-galaxy list
    ansible-playbook tempest.yaml
fi
