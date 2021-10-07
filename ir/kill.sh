#!/bin/bash

if [[ ! -e ~/virt/network/baremetal_deployment.yaml ]]; then
    echo "baremetal_deployment.yaml is missing"
    exit 1
fi

openstack overcloud delete overcloud --yes

openstack overcloud node unprovision --all -y --stack overcloud ~/virt/network/baremetal_deployment.yaml
