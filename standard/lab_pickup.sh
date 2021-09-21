#!/bin/bash

# pickup from what tripleo-lab already deployed as described
# in https://github.com/fultonj/xena/tree/main/networkv2

STACK=overcloud-0

pushd ~
sed -i \
    's|/usr/share/openstack-tripleo-heat-templates|/home/stack/templates|g' \
    overcloud-*-*-0.yaml
popd

head -10 ~/overcloud-0-yml/network-env.yaml > ~/vip_subnet_map.yaml

cp ~/overcloud-networks-provisioned-0.yaml deployed-network-$STACK.yaml
cp ~/overcloud-baremetal-deployed-0.yaml deployed-metal-$STACK.yaml

