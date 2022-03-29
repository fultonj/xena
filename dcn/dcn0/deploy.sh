#!/bin/bash

STACK=dcn0

source ~/stackrc

if [[ ! -e $PWD/deployed-ceph-$STACK.yaml ]]; then
    echo "$PWD/deployed-ceph-$STACK.yaml is missing"
    exit 1
fi

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

HEAT_POD=quay.io/tripleomaster/openstack-heat-all:current-tripleo
podman pull $HEAT_POD
echo "Runing openstack overcloud deploy"

time openstack overcloud deploy \
     --templates ~/templates/ \
     --stack $STACK \
     --timeout 90 \
     --heat-type pod --skip-heat-pull \
     --heat-container-engine-image $HEAT_POD \
     --heat-container-api-image $HEAT_POD \
     -e ~/templates/environments/network-environment.yaml \
     -e ~/templates/environments/low-memory-usage.yaml \
     -e ~/templates/environments/podman.yaml \
     -e ~/templates/environments/docker-ha.yaml \
     -e ~/templates/environments/cephadm/cephadm-rbd-only.yaml \
     -e ~/templates/environments/dcn-storage.yaml \
     -r dcn_roles.yaml \
     -n ~/oc0-network-data.yaml \
     -e ~/containers-prepare-parameter.yaml \
     -e ~/re-generated-container-prepare.yaml \
     -e ~/oc0-domain.yaml \
     -e ~/overcloud-0-yml/nova-tpm.yaml \
     -e ~/overcloud-0-yml/network-env.yaml \
     -e ~/xena/env_common/overrides.yaml \
     -e deployed-vips-$STACK.yaml \
     -e deployed-network-$STACK.yaml \
     -e deployed-metal-$STACK.yaml \
     -e deployed-ceph-$STACK.yaml \
     -e ../control-plane-export.yaml \
     -e ../ceph-export-control-plane.yaml \
     -e glance.yaml \
     -e overrides.yaml \
     --libvirt-type qemu
