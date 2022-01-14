#!/usr/bin/env bash

CLIENT=0
SPEC=1
USER=1
CEPH=1
CEPH_IP=192.168.122.252

if [ $CLIENT -eq 1 ]; then
    bash ../init/python-tripleoclient.sh
fi

if [ $SPEC -eq 1 ]; then
    sudo openstack overcloud ceph spec \
         --standalone \
         --osd-spec osd_spec.yaml \
         --mon-ip $CEPH_IP \
         -y --output ceph_spec.yaml
fi

if [ $USER -eq 1 ]; then
    sudo openstack overcloud ceph user enable \
         --standalone \
         ceph_spec.yaml
fi

if [ $CEPH -eq 1 ]; then
    sudo openstack overcloud ceph deploy \
          --standalone \
          --mon-ip $CEPH_IP \
          --ceph-spec ceph_spec.yaml \
          --config initial_ceph.conf \
          --skip-user-create \
          -y --output deployed_ceph.yaml
fi
