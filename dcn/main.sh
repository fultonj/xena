#!/bin/bash

NEW_CLIENT=0
CENTRAL_DEPLOY=1
CENTRAL_SANITY=1
CENTRAL_EXPORT=1
DCN0_DEPLOY=1
DCN1_DEPLOY=1
CENTRAL_UP=1

source ~/stackrc

if [[ $NEW_CLIENT -eq 1 ]]; then
    ../init/python-tripleoclient.sh
fi

if [[ $CENTRAL_DEPLOY -eq 1 ]]; then
    STACK=control-plane
    bash metal.sh $STACK
    bash ceph.sh $STACK
    pushd $STACK
    bash deploy.sh
    popd
fi

if [[ $CENTRAL_SANITY -eq 1 ]]; then
    echo "Verify control-plane is working"
    RC=/home/stack/control-planerc
    if [[ -e $RC ]]; then
        source $RC
        echo "Attempting to issue token from control-plane"
        openstack token issue -f value -c id
        if [[ $? -gt 0 ]]; then
            echo "Unable to issue token. Aborting."
            exit 1
        fi
        # Use undercloud by default
        source ~/stackrc
    else
        echo "$RC is missing. abort."
        exit 1
    fi
fi


if [[ $CENTRAL_EXPORT -eq 1 ]]; then
    # https://github.com/openstack/python-tripleoclient/commit/
    # 80c43280a8a17c6d06b0fe24ab7df48ef29f24e9
    if [[ ! -e control-plane-export.yaml ]]; then
        SRC=~/overcloud-deploy/control-plane/control-plane-export.yaml
        if [[ ! -e $SRC ]]; then
            echo "The export file should exist in the stack "
            echo "working directory but does not. Aborting."
            exit 1
        else
            cp -v $SRC .
        fi
    fi
    openstack overcloud export ceph -f --stack control-plane
    if [[ ! -e ceph-export-control-plane.yaml ]]; then
        echo "Failure: openstack overcloud export ceph --stack control-plane"
        exit 1
    fi
fi

if [[ $DCN0_DEPLOY -eq 1 ]]; then
    STACK=dcn0
    bash metal.sh $STACK
    bash ceph.sh $STACK
    pushd $STACK
    bash deploy.sh
    popd

    source ~/control-planerc
    openstack aggregate show dcn0
    if [[ $? -gt 0 ]]; then
        echo "openstack aggregate dcn0 was not created. Aborting."
        exit 1
    fi
    source ~/stackrc
fi

if [[ $DCN1_DEPLOY -eq 1 ]]; then
    STACK=dcn1
    bash metal.sh $STACK
    bash ceph.sh $STACK
    pushd $STACK
    bash deploy.sh
    popd
fi

if [[ $CENTRAL_UP -eq 1 ]]; then
    openstack overcloud export ceph -f --stack dcn0,dcn1
    if [[ ! -e ceph-export-2-stacks.yaml ]]; then
        echo "Failure: openstack overcloud export ceph --stack dcn0,dcn1"
        exit 1
    fi
    pushd control-plane
    if [[ -e deploy-update.sh ]]; then
        rm -f deploy-update.sh
    fi
    cp deploy.sh deploy-update.sh
    sed -i s/qemu/qemu\ \\\\/g deploy-update.sh
    sed -i s/#\ ONE/\\-e\ glance_update.yaml\ \\\\/g deploy-update.sh
    sed -i s/#\ TWO/\\-e\ \\.\\.\\/ceph-export-2-stacks.yaml/g deploy-update.sh
    bash deploy-update.sh
    popd
    echo "You may now test the deployment with validations/use-multistore-glance.sh"
fi
