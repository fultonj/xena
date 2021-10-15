#!/bin/bash

pushd ~/task-core/examples/directord/services

task-core -s . -i ~/task-core-inventory-hackfest.yaml -r ../basic/2node_roles.yaml -d

popd
