#!/bin/bash

CLEAN=1
source ~/stackrc

if [[ $CLEAN -eq 1 ]]; then
    cat /dev/null > /tmp/ironic_names_to_clean
fi

for STACK in $(ls ~/overcloud-deploy/ | egrep "dcn|control-plane"); do
    openstack overcloud delete $STACK --yes
    pushd ../metalsmith
    if [[ $CLEAN -eq 1 ]]; then
        grep name ${STACK}.yaml | grep oc0 \
            | grep -v hostname | awk {'print $2'} \
            | grep ceph >> /tmp/ironic_names_to_clean
    fi
    bash unprovision.sh $STACK
    popd
done

rm -f control-plane-export.yaml
rm -f ceph-export-control-plane.yaml
rm -f ceph-export-2-stacks.yaml
rm -rf dcn1
find . -name deployed* -exec rm -f {} \;
find . -name *_roles.yaml -exec rm -f {} \;

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
