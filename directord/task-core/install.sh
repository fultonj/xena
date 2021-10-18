#!/bin/bash

pushd ~
sudo dnf -y install cmake make gcc gcc-c++ openssl-devel
sudo dnf -y update libarchive

if [[ ! -d ~/task-core ]]; then
    git clone https://github.com/mwhahaha/task-core
fi

sudo /opt/directord/bin/pip3 install task-core/
popd

cp -v -f task-core-inventory-hackfest.yaml ~/
cp -v -f task-core-hackfest.yaml ~/
cp -v -f os-net-config.yaml.j2  ~/
cp -v -f 2node_config.yaml ~/task-core/examples/directord/services/2node_config.yaml
cp -v -f os-net-config.yaml ~/task-core/examples/directord/services/os-net-config.yaml
