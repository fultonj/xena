#!/usr/bin/env bash

CLIENT=0
ASPEC=0
CSPEC=1
USER=1
CEPH=1
IP=192.168.122.252

if [ $CLIENT -eq 1 ]; then
    bash ../init/python-tripleoclient.sh
fi

if [ $ASPEC -eq 1 ]; then
    ansible localhost -m ceph_spec_bootstrap \
      -a "deployed_metalsmith=fake_workdir/deployed_metal.yaml \
          new_ceph_spec=fake_workdir/ceph_spec.yaml
          tripleo_roles=/usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml"
fi

if [ $CSPEC -eq 1 ]; then
    sudo openstack overcloud ceph spec \
         --standalone \
         --osd-spec osd_spec.yaml \
         --mon-ip $IP \
         -y -o ceph_spec.yaml
    ls -l $PWD/ceph_spec.yaml
fi


if [ $USER -eq 1 ]; then
    sudo openstack overcloud ceph user enable \
         ceph_spec.yaml \
         --working-dir . \
         --stack standalone
fi

if [ $CEPH -eq 1 ]; then
    sudo openstack overcloud ceph deploy \
          --working-dir . \
          --network-data network_data.yaml \
          --mon-ip $IP \
          --ceph-spec ceph_spec.yaml \
          --skip-user-create \
          --container-namespace quay.io/ceph \
          --container-image daemon \
          --container-tag v6.0.6-stable-6.0-pacific-centos-8-x86_64 \
          --stack standalone \
          -y -o deployed_ceph.yaml
fi
