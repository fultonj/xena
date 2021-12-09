#!/bin/bash

NEWRPM=0
NEWPY=0
SPEC=0
USER=0
DEPLOY=0
DISABLE=0
ENABLE=0
OLD_ANSIBLE=0
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

if [[ $SPEC -eq 1 ]]; then
    # create a ceph spec file from deployed metal
    ansible localhost -m ceph_spec_bootstrap \
            -a deployed_metalsmith=deployed-metal-$STACK.yaml
    ls  -l ~/ceph_spec.yaml
fi

if [[ $USER -eq 1 ]]; then
    # create the cephadm ssh user before deploying ceph
    openstack overcloud ceph user enable \
              ~/ceph_spec.yaml \
              --stack $STACK
fi

if [[ $DEPLOY -eq 1 ]]; then
    # deploy ceph
    openstack overcloud ceph deploy -vvv \
              ~/xena/deployed_ceph/deployed-metal-$STACK.yaml \
              -y -o ~/xena/deployed_ceph/deployed_ceph.yaml \
              --network-data ~/oc0-network-data.yaml \
              --skip-user-create \
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

if [[ $DISABLE -eq 1 ]]; then
    # disable the cephadm ssh user AND disable cephadm
    openstack overcloud ceph user disable -y \
              ~/ceph_spec.yaml \
              --stack $STACK \
              --fsid $FSID
fi

if [[ $ENABLE -eq 1 ]]; then
    # re-enable the cephadm ssh user AND re-enable cephadm
    openstack overcloud ceph user enable \
              ~/ceph_spec.yaml \
              --stack $STACK \
              --fsid $FSID
fi

if [[ $OLD_ANSIBLE -eq 1 ]]; then
    # Does some of what 'openstack overcloud ceph deploy'
    # does but directly in ansible.
    ansible-playbook -i $INV \
                 -v \
                 $PLAYBOOKS/cli-deployed-ceph.yaml \
                 -e baremetal_deployed_path="$PWD/deployed-metal-$STACK.yaml" \
                 -e deployed_ceph_tht_path="$PWD/generated_deployed_ceph.yaml" \
                 -e tripleo_cephadm_container_image="daemon" \
                 -e tripleo_cephadm_container_ns="quay.ceph.io/ceph-ci" \
                 -e tripleo_cephadm_container_tag="latest-pacific-devel" \
                 -e working_dir="$WORKING_DIR"
fi

# REMOVE CEPH (and try again)
if [[ $CLEAN -eq 1 ]]; then
    ansible-playbook -i $INV rm_ceph.yaml
fi
