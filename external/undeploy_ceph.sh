#!/bin/bash

STACK=ceph-e
CLEAN=1

TMP=/tmp/ceph_nodes_$STACK
METAL=deployed-metal-$STACK.yaml
grep cephall $METAL \
    | grep -v CephAllHostnameFormat \
    | awk {'print $2'} > $TMP

pushd ../metalsmith
bash unprovision.sh $STACK
rm -f deployed-{metal,network}-$STACK.yaml
popd

if [[ $CLEAN -eq 1 ]]; then
    for H in $(cat $TMP); do
        bash ../metalsmith/clean-disks.sh $H
    done
fi
rm -f $TMP
