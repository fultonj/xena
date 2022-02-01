#!/bin/bash

if [[ -e vars ]]; then
    source vars
fi

pushd ~/infrared
source .venv/bin/activate
infrared tripleo-overcloud -v \
         --version 17.0 \
         --deployment-files virt \
         --overcloud-templates=none \
         --overcloud-debug yes \
         --network-backend geneve \
         --network-l2gw false \
         --network-protocol ipv4 \
         --network-dvr false \
         --network-ovs false \
         --network-bgpvpn false \
         --storage-backend ceph \
         --tls-everywhere no  \
         --overcloud-ssl no \
         --ntp-pool clock.redhat.com \
         --enable-novajoin true \
         --network-ovn true \
         --introspect yes \
         --tagging yes \
         --deploy yes
popd
