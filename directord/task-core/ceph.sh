#!/bin/bash

# Clean cache on all nodes
# directord exec --verb CACHEEVICT all

# Purge jobs from server
# directord manage --purge-jobs

cp -v -f task-core-inventory-ceph.yaml ~/
cp -v -f task-core-ceph.yaml ~/
cp -v -f 2node_config.yaml ~/task-core/examples/directord/services/2node_config.yaml

pushd ~/task-core/examples/directord/services

task-core -s . -i ~/task-core-inventory-hackfest.yaml -r ../basic/2node_roles.yaml -d

popd
