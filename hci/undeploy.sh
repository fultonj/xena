#!/bin/bash

CLEAN=1
STACK=hci
METAL=deployed-metal-$STACK.yaml
TMP=/tmp/ceph_nodes_$STACK
grep computehci $METAL \
    | grep -v CephStorageHostnameFormat \
    | grep -v index \
    | awk {'print $2'} > $TMP

openstack overcloud delete $STACK --yes

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-{metal,network}-$STACK.yaml
popd

for F in generated_ceph_spec.yaml generated_deployed_ceph.yaml deployed-{metal,network}-$STACK.yaml cirros-0.4.0-x86_64-disk.{raw,img} tempest-deployer-input.conf; do
    if [[ -e $F ]]; then
        rm -f $F
    fi
done

if [[ $CLEAN -eq 1 ]]; then
    for H in $(cat $TMP); do
        bash ../metalsmith/clean-disks.sh $H
    done
fi
rm -f $TMP
