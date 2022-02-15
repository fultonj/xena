#!/bin/bash

if [[ -e vars ]]; then
    source vars
fi

pushd ~/infrared
source .venv/bin/activate
infrared tripleo-undercloud -v \
         --mirror=rdu2 \
         --version 17.0 \
         --tls-everywhere no \
         --images-task rpm \
         --images-update no \
         --tls-ca $TLS_CA \
         --config-options DEFAULT.undercloud_timezone=UTC \
         --build $BUILD \
         --enable-novajoin 'yes'
popd
