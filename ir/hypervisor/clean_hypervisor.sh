#!/bin/bash

# clean out old IR
find ~ -name .infrared -exec rm -rf {} \;

pushd ~/infrared
source .venv/bin/activate
infrared virsh -v \
     --host-address $HOSTNAME \
     --host-key ~/.ssh/rhos-jenkins \
     --cleanup=yes
popd
