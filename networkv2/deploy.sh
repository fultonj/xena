#!/bin/bash

STACK=overcloud-0
source ~/stackrc;

openstack overcloud deploy \
          --templates ~/templates \
          --stack $STACK \
          -e ~/templates/environments/net-single-nic-with-vlans.yaml \
          -e ~/templates/environments/deployed-server-deployed-neutron-ports.yaml \
          -e ~/templates/environments/disable-telemetry.yaml \
          -e ~/templates/environments/low-memory-usage.yaml \
          -e ~/templates/environments/podman.yaml \
          -r ~/oc0-role-data.yaml \
          -n ~/oc0-network-data.yaml \
          -e ~/overcloud-vips-provisioned-0.yaml \
          -e ~/overcloud-networks-provisioned-0.yaml \
          -e ~/overcloud-baremetal-deployed-0.yaml \
          -e ~/vip_subnet_map.yaml \
          -e ~/containers-prepare-parameter.yaml \
          -e ~/generated-container-prepare.yaml \
          -e ~/oc0-domain.yaml \
          --disable-validations --deployed-server
