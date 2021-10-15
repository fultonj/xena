#!/bin/bash

# Clean cache on all nodes
# directord exec --verb CACHEEVICT all

# Purge jobs from server
# directord manage --purge-jobs


pushd ~/task-core/examples/directord/services

task-core -s . -i ~/task-core-inventory-hackfest.yaml -r ../basic/2node_roles.yaml -d

popd
