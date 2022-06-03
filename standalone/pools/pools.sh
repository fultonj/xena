#!/usr/bin/env bash

if [[ ! -e pools.yml ]]; then
    echo "pools.yml is missing"
    exit 1
fi
if [[ ! -d  ~/tripleo-ansible ]]; then
    echo "~/tripleo-ansible is missing"
    exit 1
fi
# cp playbook and vars to use relative paths in tripleo-ansible
cp -v -f pools.yml ~/tripleo-ansible/
cp -v -f vars_from_external_deploy_steps_tasks_step2.yaml ~/tripleo-ansible/

pushd ~/tripleo-ansible/
ansible-playbook \
    --module-path "~/.ansible/plugins/modules/:/usr/share/ansible/plugins/modules:~/tripleo-ansible/plugins/modules/" \
    --extra-vars '{"ansible_env": {"HOME": "/home/stack/"}}' \
    pools.yml
popd
rm -v -f ~/tripleo-ansible/pools.yml
rm -v -f ~/tripleo-ansible/vars_from_external_deploy_steps_tasks_step2.yaml

