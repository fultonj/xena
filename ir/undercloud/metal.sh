#!/bin/bash

if [[ ! -e /home/stack/composable_roles/network/baremetal_deployment.yaml ]]; then
    echo "baremetal_deployment.yaml is missing"
    exit 1
fi

openstack overcloud node provision --network-config --stack overcloud --output ~/templates/overcloud-baremetal-deployed.yaml /home/stack/composable_roles/network/baremetal_deployment.yaml

ls -l ~/templates/overcloud-baremetal-deployed.yaml

echo "Run the following script now"
echo "overcloud_deploy.sh"
