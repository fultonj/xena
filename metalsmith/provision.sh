#!/bin/bash

source ~/stackrc
STACK=$1
NETWORK=1
PROVISION_CONCURRENCY=2
# ^ boolean deploy network

if [[ -z $STACK ]]; then
    echo "Usage: $0 <STACK_NAME>"
    exit 1
fi

# VIPs
VIP="$PWD/deployed-vips-${STACK}.yaml"
if [[ ! -e $VIP ]]; then
    echo "Creating $VIP"
    VIP_SRC=/home/stack/overcloud-vips-provisioned-0.yaml
    if [[ ! -e $VIP_SRC  ]]; then
        echo "Missing VIPS file: $VIP_SRC"
        exit 1
    fi
    cp $VIP_SRC $VIP
    sed -i \
        's|/usr/share/openstack-tripleo-heat-templates|/home/stack/templates|g' \
        $VIP
fi
if [[ ! -e $VIP ]]; then
    echo "$VIP is still missing"
    exit 1
fi

# NETWORK
NETWORK_OUTPUT_FILE="$PWD/deployed-network-${STACK}.yaml"
if [[ $NETWORK -eq 1 ]]; then
    if [[ ! -e ~/oc0-network-data.yaml ]]; then
        echo "Exiting: ~/oc0-network-data.yaml is missing"
        exit 1
    fi
    if [[ -e $NETWORK_OUTPUT_FILE ]]; then
        rm -f -v $NETWORK_OUTPUT_FILE
    fi
    echo "Deploying network from network_data.yaml and creating $NETWORK_OUTPUT_FILE"
    openstack overcloud network provision \
              --output $NETWORK_OUTPUT_FILE \
              ~/oc0-network-data.yaml
    sed -i 's|/usr/share/openstack-tripleo-heat-templates|/home/stack/templates|g' $NETWORK_OUTPUT_FILE
else
    if [[ ! -e $NETWORK_OUTPUT_FILE ]]; then
        cp ~/overcloud-networks-provisioned-0.yaml $NETWORK_OUTPUT_FILE
    fi
fi

# METAL
NODE_FILE="$PWD/${STACK}.yaml"
if [[ ! -e $NODE_FILE ]]; then
    echo "Exiting: the file node_file ($NODE_FILE) does not exist."
    exit 1
fi
METAL_OUTPUT_FILE="$PWD/deployed-metal-${STACK}.yaml"
if [[ -e $METAL_OUTPUT_FILE ]]; then
    rm -f -v $METAL_OUTPUT_FILE
fi

if [[ ! -z $STACK && ! -z $NODE_FILE ]]; then
    echo "Provisioning stack ($STACK) from ($NODE_FILE) and creating $METAL_OUTPUT_FILE"
    openstack overcloud node provision \
              --network-config \
              --stack $STACK \
              --concurrency $PROVISION_CONCURRENCY \
              --output $METAL_OUTPUT_FILE \
              $NODE_FILE
    if [[ -e $METAL_OUTPUT_FILE ]]; then
        sed -i 's|/usr/share/openstack-tripleo-heat-templates|/home/stack/templates|g' $METAL_OUTPUT_FILE
    fi
else
    echo "Exiting: stack ($STACK) and node_file ($NODE_FILE) are not both defined"
    exit 1
fi
