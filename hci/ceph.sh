#!/bin/bash

DEPLOY=1
CLEAN=0

STACK=hci
WORKING_DIR="$HOME/overcloud-deploy/${STACK}"
INV="$WORKING_DIR/tripleo-ansible-inventory.yaml"

if [[ $DEPLOY -eq 1 ]]; then
    openstack overcloud ceph deploy \
              deployed-metal-$STACK.yaml \
              -y -o deployed_ceph.yaml \
              --roles-data hci-role-data.yaml \
              --network-data ~/oc0-network-data.yaml \
              --container-image-prepare ~/containers-prepare-parameter.yaml \
              --cephadm-extra-args '--log-to-file --skip-prepare-host' \
              --force \
              --config assimilate_ceph.conf \
              --skip-user-create \
              --skip-hosts-config \
              --skip-container-registry-config \
              --stack $STACK
fi

# REMOVE CEPH (and try again)
if [[ $CLEAN -eq 1 ]]; then
    pushd ../deployed_ceph/
    ansible-playbook -i $INV rm_ceph.yaml
    popd
fi
