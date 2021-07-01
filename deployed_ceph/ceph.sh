#!/bin/bash

CEPH=1
CLEAN=0

# GET AN INVENTORY
STACK=overcloud-0
# STACK=other-3
WORKING_DIR="$HOME/overcloud-deploy/${STACK}"
INV="$WORKING_DIR/tripleo-ansible-inventory.yaml"
# This inventory is a result of baremetal provisioning, see:
#   tripleo_ansible/playbooks/cli-overcloud-node-provision.yaml
PLAYBOOKS="$HOME/tripleo-ansible/tripleo_ansible/playbooks"

if [[ $CEPH -eq 1 ]]; then
    ansible-playbook -i $INV \
                 -v \
                 $PLAYBOOKS/cli-deployed-ceph.yaml \
                 -e baremetal_deployed_path="$PWD/deployed-metal-$STACK.yaml" \
                 -e deployed_ceph_tht_path="$PWD/generated_deployed_ceph.yaml" \
                 -e dynmaic_ceph_spec=true \
                 -e tripleo_cephadm_container_image="daemon" \
                 -e tripleo_cephadm_container_ns="quay.ceph.io/ceph-ci" \
                 -e tripleo_cephadm_container_tag="latest-pacific-devel" \
                 -e working_dir="$WORKING_DIR"

    # Custom crush rules should be set manually via cephadm
fi

# REMOVE CEPH (and try again)
if [[ $CLEAN -eq 1 ]]; then
    ansible-playbook -i $INV rm_ceph.yaml
fi
