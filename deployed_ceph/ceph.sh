#!/bin/bash

USER=1

# GET AN INVENTORY
STACK=overcloud-0
# STACK=other-3
WORKING_DIR="$HOME/overcloud-deploy/${STACK}"
INV="$WORKING_DIR/tripleo-ansible-inventory.yaml"
# This inventory is a result of baremetal provisioning, see:
#   tripleo_ansible/playbooks/cli-overcloud-node-provision.yaml
ROLES="/usr/share/openstack-tripleo-heat-templates/roles_data.yaml"
PLAYBOOKS="$HOME/tripleo-ansible/tripleo_ansible/playbooks"

# CREATE CEPHADM USER
if [[ USER -eq 1 ]]; then
    # We will want to map composed $ROLES to groups based on services
    # For now we assume defaults
    #CEPHADM_PUBLIC_PRIVATE_SSH_LIST="undercloud,ceph_mon,ceph_mgr"
    CEPHADM_PUBLIC_PRIVATE_SSH_LIST="undercloud,Controller"
    #CEPHADM_PUBLIC_SSH_LIST="undercloud,ceph_osd,ceph_rgw,ceph_mds,ceph_nfs,ceph_rbdmirror"
    CEPHADM_PUBLIC_SSH_LIST="undercloud,CephStorage"

    ansible-playbook -i $INV \
                     $PLAYBOOKS/ceph-admin-user-playbook.yml \
                     -e tripleo_admin_user=ceph-admin \
                     -e distribute_private_key=true \
                     --limit $CEPHADM_PUBLIC_PRIVATE_SSH_LIST

    ansible-playbook -i $INV \
                     $PLAYBOOKS/ceph-admin-user-playbook.yml \
                     -e tripleo_admin_user=ceph-admin \
                     -e distribute_private_key=false \
                     --limit $CEPHADM_PUBLIC_SSH_LIST
fi

# DEPLOY CEPH
ansible-playbook -i $INV \
                 -v \
                 $PLAYBOOKS/cli-deployed-ceph.yaml \
                 -e baremetal_deployed_path="$PWD/deployed-metal-other-3.yaml" \
                 -e new_ceph_spec_path="$PWD/generated_ceph_spec.yaml" \
                 -e new_deployed_ceph_tht_path="$PWD/cephadm-overrides.yaml"

# Custom crush rules should be set manually via cephadm
