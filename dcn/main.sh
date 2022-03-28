#!/bin/bash

NEW_CLIENT=0
CENTRAL_DEPLOY=0
CENTRAL_SANITY=0
CENTRAL_EXPORT=0
DCN0_DEPLOY=1
DCN1_DEPLOY=0
DCN_EXPORT=0

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
fi
