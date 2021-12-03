#!/bin/bash

IRONIC=0
CLEAN=0
NEWRPM=0
NEW_CLIENT=1
USER=1
CEPH=0

STACK=ceph-e
WORKING_DIR="$HOME/overcloud-deploy/${STACK}"
INV="$WORKING_DIR/tripleo-ansible-inventory.yaml"

source ~/stackrc
# -------------------------------------------------------
METAL="../metalsmith/deployed-metal-${STACK}.yaml"
NET="../metalsmith/deployed-network-${STACK}.yaml"
if [[ $IRONIC -eq 1 ]]; then
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing. Deploying nodes with metalsmith."
        pushd ../metalsmith
        bash provision.sh $STACK
        popd
    fi
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing after deployment attempt. Going to retry once."
        pushd ../metalsmith
        bash undeploy_failures.sh
        bash provision.sh $STACK
        popd
        if [[ ! -e $METAL ]]; then
            echo "$METAL is still missing. Aborting."
            exit 1
        fi
    fi
    echo "Finished with baremetal"
fi
if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    cp $METAL deployed-metal-$STACK.yaml
    cp $NET deployed-network-$STACK.yaml
fi
# -------------------------------------------------------
# REMOVE CEPH (and try again)
if [[ $CLEAN -eq 1 ]]; then
    ansible-playbook -i $INV ../deployed_ceph/rm_ceph.yaml
fi
# -------------------------------------------------------
if [[ $NEWRPM -eq 1 ]]; then
    RPM=https://cbs.centos.org/kojifiles/packages/cephadm/16.2.6/1.el8s/noarch/cephadm-16.2.6-1.el8s.noarch.rpm
    ansible -i $INV CephAll -b -m dnf -a "name=$RPM disable_gpg_check=yes state=present"
fi
# -------------------------------------------------------
if [[ $NEW_CLIENT -eq 1 ]]; then
    bash ../init/python-tripleoclient.sh
fi
# -------------------------------------------------------
if [[ $USER -eq 1 ]]; then
    #openstack overcloud ceph user disable --help
    openstack overcloud ceph user re-enable --help
fi
# -------------------------------------------------------
if [[ $CEPH -eq 1 ]]; then
    openstack overcloud ceph deploy \
              $PWD/deployed-metal-$STACK.yaml \
              -y -o $PWD/deployed_ceph.yaml \
              --network-data oc0-network-data.yaml \
              --roles-data $PWD/ceph_roles.yaml \
              --container-namespace quay.io/ceph \
              --container-image daemon \
              --container-tag v6.0.4-stable-6.0-pacific-centos-8-x86_64 \
              --stack $STACK
    #          --config assimilate_ceph.conf \
fi
