#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "USAGE: $0 <STACK>"
    exit 1
fi
export STACK=$1
if [[ ! -d $STACK ]]; then
    echo "The directory $STACK was not found."
    exit 1
fi
echo "Deploying ceph for $STACK"
pushd $STACK

if [[ $STACK == "control-plane" ]]; then
    export ROLES=control_plane_roles.yaml
else
    export ROLES=dcn_roles.yaml
fi
echo "Using roles file: $ROLES"

source ~/stackrc

openstack overcloud ceph deploy \
          $PWD/deployed-metal-$STACK.yaml \
          -y -o $PWD/deployed-ceph-$STACK.yaml \
          --container-image-prepare ~/containers-prepare-parameter.yaml \
          --network-data ~/oc0-network-data.yaml \
          --roles-data $ROLES \
          --stack $STACK

popd
