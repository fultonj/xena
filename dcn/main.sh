#!/bin/bash

STACK=control-plane
bash metal.sh $STACK
bash ceph.sh $STACK
pushd $STACK
bash deploy.sh
popd

