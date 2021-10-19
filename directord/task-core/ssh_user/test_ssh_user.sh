#!/bin/bash

# Clean cache on all nodes
# directord exec --verb CACHEEVICT all

# Purge jobs from server
# directord manage --purge-jobs

cp -v -f task-core-inventory-ssh-user.yaml ~/
cp -v -f task-core-ssh-user.yaml ~/
cp -v -f 2node_roles_ssh_user.yaml ~/task-core/examples/directord/basic/2node_roles_ssh_user.yaml
cp -v -f 2node_config.yaml ~/task-core/examples/directord/services/2node_config.yaml

pushd ~/task-core/examples/directord/services

task-core -s . -i ~/task-core-inventory-ssh-user.yaml -r ../basic/2node_roles_ssh_user.yaml -d

popd
