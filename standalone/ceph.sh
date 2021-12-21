#!/usr/bin/env bash

SPEC=0
USER=1
CLI=1
KILL=0

if [ $SPEC -eq 1 ]; then
    ansible localhost -m ceph_spec_bootstrap \
      -a "deployed_metalsmith=fake_workdir/deployed_metal.yaml \
          new_ceph_spec=fake_workdir/ceph_spec.yaml
          tripleo_roles=/usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml"
fi

if [ $USER -eq 1 ]; then
    sudo openstack overcloud ceph user enable \
              fake_workdir/ceph_spec.yaml \
              --working-dir fake_workdir \
              --stack standalone
fi

if [ $CLI -eq 1 ]; then
    sudo openstack overcloud ceph deploy \
          fake_workdir/deployed_metal.yaml \
          --working-dir fake_workdir \
          --network-data fake_workdir/network_data.yaml \
          --roles-data /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
          --ceph-spec fake_workdir/ceph_spec.yaml \
          --skip-user-create \
          --container-namespace quay.io/ceph \
          --container-image daemon \
          --container-tag v6.0.6-stable-6.0-pacific-centos-8-x86_64 \
          --stack standalone \
          -y -o deployed_ceph.yaml
fi

if [ $KILL -eq 1 ]; then
    FSID=$(sudo cephadm ls --no-detail | jq .[].fsid | head -1 | sed s/\"//g)
    sudo systemctl stop ceph-osd@*
    sudo /usr/sbin/cephadm zap-osds --force --fsid $FSID
    sudo /usr/sbin/cephadm rm-cluster --force --fsid $FSID
    sudo lvremove /dev/vg2/data-lv2 --yes
    sudo vgremove /dev/vg2 --yes
    bash disks.sh
    lsblk
fi
