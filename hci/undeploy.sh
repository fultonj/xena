#!/bin/bash

CLEAN=1
STACK=hci

openstack overcloud delete $STACK --yes

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-metal-$STACK.yaml
popd

for F in deployed-metal-$STACK.yaml cirros-0.4.0-x86_64-disk.{raw,img} tempest-deployer-input.conf; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done

if [[ $CLEAN -eq 1 ]]; then
    for I in $(seq 0 2); do
        bash ../metalsmith/clean-disks.sh oc0-ceph-$I
    done
fi
