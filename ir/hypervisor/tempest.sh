#!/bin/bash

if [[ -e vars ]]; then
    source vars
fi

pushd ~/infrared
source .venv/bin/activate
infrared tempest --tests=sanity \
         --openstack-version 17.0 \
         --openstack-installer tripleo
popd
