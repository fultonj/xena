#!/bin/bash

NEWRPM=1
NEWPY=0
PYTHON=1
SCRIPT=0
CLEAN=0

# GET AN INVENTORY
STACK=overcloud-0
# STACK=other-3
WORKING_DIR="$HOME/overcloud-deploy/${STACK}"
INV="$WORKING_DIR/tripleo-ansible-inventory.yaml"
# This inventory is a result of baremetal provisioning, see:
#   tripleo_ansible/playbooks/cli-overcloud-node-provision.yaml
PLAYBOOKS="$HOME/tripleo-ansible/tripleo_ansible/playbooks"

if [[ $NEWRPM -eq 1 ]]; then
    RPM=https://cbs.centos.org/kojifiles/packages/cephadm/16.2.5/1.el8/noarch/cephadm-16.2.5-1.el8.noarch.rpm
    ansible -i $INV CephStorage,Controller -b -m dnf -a "name=$RPM disable_gpg_check=yes state=present"
fi

if [[ $NEWPY -eq 1 ]]; then
    ~/xena/init/python-tripleoclient.sh
fi

if [[ $PYTHON -eq 1 ]]; then

    #openstack overcloud ceph deploy --help
    openstack overcloud ceph deploy -vvv \
              ~/xena/deployed_ceph/deployed-metal-$STACK.yaml \
              -y -o ~/xena/deployed_ceph/deployed_ceph.yaml \
              --container-namespace quay.io/ceph \
              --container-image daemon \
              --container-tag v6.0.4-stable-6.0-pacific-centos-8-x86_64 \
              --stack $STACK

    # --ceph-spec ~/xena/deployed_ceph/ceph_spec.yaml \
    # --osd-spec ~/xena/deployed_ceph/osd_spec.yaml \
    # --roles-data foo.yaml \
    #
    # --container-namespace quay.io/ceph \
    # --container-image daemon \
    # --container-tag v6.0.4-stable-6.0-pacific-centos-8-x86_64 \
    #
    # --registry-url registry.redhat.io \
    # --registry-username fultonj \
    # --registry-password Sl4y3rR2lz \

fi

if [[ $SCRIPT -eq 1 ]]; then
    ansible-playbook -i $INV \
                 -v \
                 $PLAYBOOKS/cli-deployed-ceph.yaml \
                 -e baremetal_deployed_path="$PWD/deployed-metal-$STACK.yaml" \
                 -e deployed_ceph_tht_path="$PWD/generated_deployed_ceph.yaml" \
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
