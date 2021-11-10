#!/bin/bash

IRONIC=0
NEW_CLIENT=1
CEPH=1

STACK=ceph-e
NODE_COUNT=3

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
if [[ $NEW_CLIENT -eq 1 ]]; then
    bash ../init/python-tripleoclient.sh
fi
# -------------------------------------------------------
if [[ $CEPH -eq 1 ]]; then
    openstack overcloud ceph deploy -vvv \
              $PWD/deployed-metal-$STACK.yaml \
              -y -o $PWD/deployed_ceph.yaml \
              --network-data ~/oc0-network-data.yaml \
              --roles-data $PWD/ceph_roles.yaml \
              --container-namespace quay.io/ceph \
              --container-image daemon \
              --container-tag v6.0.4-stable-6.0-pacific-centos-8-x86_64 \
              --stack $STACK
fi
