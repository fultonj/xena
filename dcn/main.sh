#!/bin/bash

NEW_CLIENT=0
METAL=1
CEPH=1
EXPORT_CEPH=1
CENTRAL_DEPLOY=0
CENTRAL_SANITY=0
CENTRAL_EXPORT=0
DCN0_DEPLOY=0
DCN1_DEPLOY=0

source ~/stackrc

if [[ $NEW_CLIENT -eq 1 ]]; then
    ../init/python-tripleoclient.sh
fi

if [[ $METAL -eq 1 ]]; then
    echo "Deploying Metal for 3 sites"
    for STACK in control-plane dcn0 dcn1; do
        ./metal.sh $STACK;
    done
fi

if [[ $CEPH -eq 1 ]]; then
    echo "Deploying Ceph on 3 sites"
    for STACK in control-plane dcn0 dcn1; do
        ./ceph.sh $STACK;
    done
fi

if [[ $EXPORT_CEPH -eq 1 ]]; then
    openstack overcloud export ceph -f \
              --config-download-dir /home/stack/overcloud-deploy/ \
              --stack control-plane
    openstack overcloud export ceph -f \
              --config-download-dir /home/stack/overcloud-deploy/ \
              --stack dcn0,dcn1
    if [[ ! -e ceph-export-control-plane.yaml ]]; then
        echo "Failure: exporting ceph from control-plane site"
        exit 1
    fi
    if [[ ! -e ceph-export-2-stacks.yaml ]]; then
        echo "Failure: exporting ceph from dcn0 and dcn1 site"
        exit 1
    fi
fi

if [[ $CENTRAL_DEPLOY -eq 1 ]]; then
    STACK=control-plane
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
fi

if [[ $DCN0_DEPLOY -eq 1 ]]; then
    STACK=dcn0
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
    pushd $STACK
    bash deploy.sh
    popd
    echo "You may now test the deployment with validations/use-multistore-glance.sh"
fi
