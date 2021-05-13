#!/bin/bash

pushd ~/tripleo-lab

sudo /usr/local/bin/lab-destroy

ansible-playbook -i inventory.yaml config-host.yaml

bash ../nethack.sh

time ansible-playbook -i inventory.yaml builder.yaml \
    -e @environments/centos-8.yaml \
    -e @environments/stream.yaml \
    -e @environments/podman.yaml \
    -e @environments/vm-centos8.yaml \
    -e @environments/metalsmith.yaml \
    -e @environments/overrides.yml \
    -e @environments/topology-standard.yml

popd
