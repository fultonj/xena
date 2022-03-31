#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "USAGE: $0 <STACK>"
    exit 1
fi
export STACK=$1
if [[ ! -d $STACK ]]; then
    echo "The directory $STACK was not found."
    exit 1
fi
echo "Deploying metal for $STACK"
pushd $STACK

METAL="../../metalsmith/deployed-metal-${STACK}.yaml"
NET="../../metalsmith/deployed-network-${STACK}.yaml"
VIP="../../metalsmith/deployed-vips-${STACK}.yaml"

if [[ ! -e $METAL ]]; then
    echo "$METAL is missing. Deploying nodes with metalsmith."
    pushd ../../metalsmith
    bash provision.sh $STACK
    popd
fi
if [[ ! -e $METAL ]]; then
    echo "$METAL is missing after deployment attempt. Going to retry once."
    pushd ../../metalsmith
    bash undeploy_failures.sh
    if [ ! $? -eq 0 ]; then
        echo "Please update nodes in Ironic."
        exit 1
    fi
    bash provision.sh $STACK
    popd
    if [[ ! -e $METAL ]]; then
        echo "$METAL is still missing. Aborting."
        exit 1
    fi
fi

if [[ ! -e deployed-metal-$STACK.yaml ]]; then
    cp $METAL deployed-metal-$STACK.yaml
    cp $NET deployed-network-$STACK.yaml
    cp $VIP deployed-vips-$STACK.yaml
fi

popd
