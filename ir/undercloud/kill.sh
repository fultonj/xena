#!/bin/bash

if [[ ! -e /home/stack/composable_roles/network/baremetal_deployment.yaml ]]; then
    echo "baremetal_deployment.yaml is missing"
    exit 1
fi

openstack overcloud delete overcloud --yes

openstack overcloud node unprovision --all -y --stack overcloud /home/stack/composable_roles/network/baremetal_deployment.yaml
