#!/bin/bash

CLEAN=1
#STACK=other-3
STACK=overcloud-0
METAL=deployed-metal-$STACK.yaml
grep cephstorage $METAL \
    | grep -v CephStorageHostnameFormat \
    | awk {'print $2'} > /tmp/ceph_nodes

openstack overcloud delete $STACK --yes

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-{metal,network}-$STACK.yaml
popd

for F in deployed-{metal,network}-$STACK.yaml cirros-0.4.0-x86_64-disk.{raw,img} tempest-deployer-input.conf; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done

if [[ $CLEAN -eq 1 ]]; then
    for H in $(cat /tmp/ceph_nodes); do
        bash ../metalsmith/clean-disks.sh $H
    done
fi
rm /tmp/ceph_nodes
