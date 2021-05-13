#!/bin/bash

source ~/stackrc
STACK=$1

if [[ -z $STACK ]]; then
    metalsmith -f value -c "Node Name" list > /tmp/metal_nodes
    COUNT=$(cat /tmp/metal_nodes | wc -l)
    if [[ $COUNT == 0 ]]; then
        echo "No metalsmith nodes are currently deployed"
        exit 1
    fi
    FIVE=$(grep oc0-ceph-5 /tmp/metal_nodes | wc -l)
    rm -f /tmp/metal_nodes
    if [[ $COUNT == 9 && $FIVE == 1 ]]; then
        for F in ~/metalsmith-0.yaml ~/tripleo_overcloud_node_provision.sh; do
            if [[ ! -e $F ]]; then
                echo "Exiting: file $F does not exist"
                exit 1
            fi
        done
        # using heuristic (can't seem to ask metalsmith what stack deployed nodes are from)
        echo "Cleaning up the initial deployment from tripleo-lab"
        STACK=$(grep "export PROVISION_STACK" ~/tripleo_overcloud_node_provision.sh \
                    | awk 'BEGIN { FS = "=" } ; { print $2 }')
        NODE_FILE=~/metalsmith-0.yaml
    fi
else
    NODE_FILE="${STACK}.yaml"
    OUTPUT_FILE="deployed-metal-${STACK}.yaml"
fi

if [[ ! -z $STACK && ! -z $NODE_FILE ]]; then
    echo "Unprovisioning stack ($STACK) created from file ($NODE_FILE)"
    openstack overcloud node unprovision --all -y \
              --stack $STACK \
              $NODE_FILE
    rm -f -v $OUTPUT_FILE
else
    echo "Exiting: stack ($STACK) and node_file ($NODE_FILE) are not both defined"
    exit 1
fi
