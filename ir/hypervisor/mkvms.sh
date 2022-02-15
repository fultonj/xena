#!/bin/bash

if [[ -e vars ]]; then
    source vars
fi

pushd ~/infrared
source .venv/bin/activate
infrared virsh -v \
         --host-address $HOSTNAME \
         --host-key ~/.ssh/id_rsa \
         --image-url $IMAGE_URL \
         --collect-ansible-facts False \
         --serial-files True \
         --topology-nodes undercloud:1,controller:3,compute:2,ceph:3 \
         --topology-network 3_nets \
         -e override.controller.cpu=8 \
         -e override.controller.memory=32768
popd

sudo virsh list
