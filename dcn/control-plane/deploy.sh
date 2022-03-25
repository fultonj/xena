#!/bin/bash

STACK=control-plane

source ~/stackrc

if [[ ! -d ~/templates ]]; then
    ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
fi

if [[ ! -e deployed-ceph-$STACK.yaml ]]; then
    echo "deployed-ceph-$STACK.yaml is missing, why didn't ceph.sh make it?"
    exit 1
fi

HEAT_POD=quay.io/tripleomaster/openstack-heat-all:current-tripleo
podman pull $HEAT_POD
echo "Runing openstack overcloud deploy"

# Use this as needed to speed up stack updates
# --disable-container-prepare \
    
time openstack overcloud deploy \
     --templates ~/templates \
     --stack $STACK \
     --timeout 90 \
     --heat-type pod --skip-heat-pull \
     --heat-container-engine-image $HEAT_POD \
     --heat-container-api-image $HEAT_POD \
     -e ~/templates/environments/network-environment.yaml \
     -e ~/templates/environments/low-memory-usage.yaml \
     -e ~/templates/environments/podman.yaml \
     -e ~/templates/environments/docker-ha.yaml \
     -e ~/templates/environments/cephadm/cephadm.yaml \
     -r control_plane_roles.yaml \
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
     -e overrides.yaml \
     --libvirt-type qemu
     # ONE
     # TWO

# For stack updates when central dcn will use dcn{0,1} ceph clusters
# -e glance_update.yaml \
# -e ../ceph-export-2-stacks.yaml \

