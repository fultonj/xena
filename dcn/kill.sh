#!/bin/bash

CLEAN=1
source ~/stackrc

if [[ $# -eq 0 ]] ; then
    STACKS=$(ls ~/overcloud-deploy/ | egrep "dcn|control-plane")
else
    STACKS=$1
fi

if [[ $CLEAN -eq 1 ]]; then
    cat /dev/null > /tmp/ironic_names_to_clean
fi

for STACK in $STACKS; do
    openstack overcloud delete $STACK --yes
    pushd ../metalsmith
    if [[ $CLEAN -eq 1 ]]; then
        grep name ${STACK}.yaml | grep oc0 \
            | grep -v hostname | awk {'print $2'} \
            | grep ceph >> /tmp/ironic_names_to_clean
    fi
    bash unprovision.sh $STACK
    popd
    # remove deployed files
    find $STACK -name deployed* -exec rm -f {} \;
    # remove export files
    if [[ $STACK == "control-plane" ]]; then
        rm -v -f control-plane-export.yaml ceph-export-control-plane.yaml
    else
        rm -v -f ceph-export-2-stacks.yaml
    fi
done

if [[ $CLEAN -eq 1 ]]; then
    for S in $(cat /tmp/ironic_names_to_clean); do
        # make sure metalsmith is done unprovisioning before cleaning
        metalsmith show $S
        while [[ $? -eq 0 ]]; do
            # we want to wait until we have an error return code (>0)
            # becasue that will mean metalsmith does not know about $S
            # and thus $S is free to be cleaned
            sleep 5
            metalsmith show $S
        done
        bash ../metalsmith/clean-disks.sh $S
    done
fi
