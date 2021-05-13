#!/bin/bash

source ~/stackrc
STACK=$1
if [[ -z $STACK ]]; then
    echo "Usage: $0 <STACK_NAME>"
    exit 1
else
    NODE_FILE="${STACK}.yaml"
    if [[ ! -e $NODE_FILE ]]; then
        echo "Exiting: the file node_file ($NODE_FILE) does not exist."
        exit 1
    fi
    OUTPUT_FILE="deployed-metal-${STACK}.yaml"
    if [[ -e $OUTPUT_FILE ]]; then
        rm -f -v $OUTPUT_FILE
    fi
fi

if [[ ! -z $STACK && ! -z $NODE_FILE ]]; then
    echo "Provisioning stack ($STACK) from ($NODE_FILE) and creating $OUTPUT_FILE"
    openstack overcloud node provision \
              --stack $STACK \
              --output $OUTPUT_FILE \
              $NODE_FILE
    if [[ -e $OUTPUT_FILE ]]; then
        sed -i \
   s/\\/usr\\/share\\/openstack\\-tripleo\\-heat\\-templates/\\/home\\/stack\\/templates/g \
   $OUTPUT_FILE                                            #^ this is the second arg
    fi
else
    echo "Exiting: stack ($STACK) and node_file ($NODE_FILE) are not both defined"
    exit 1
fi
