#!/bin/bash

IRONIC=0
HEAT=1
DOWN=0

STACK=overcloud-0
NODE_COUNT=7
# STACK=standard-3
# NODE_COUNT=3
DIR=/home/stack/overcloud-deploy/$STACK/config-download

source ~/stackrc
# -------------------------------------------------------
METAL="../metalsmith/deployed-metal-${STACK}.yaml"
NET="../metalsmith/deployed-network-${STACK}.yaml"
VIP="../metalsmith/deployed-vips-${STACK}.yaml"
if [[ $IRONIC -eq 1 ]]; then
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing. Deploying nodes with metalsmith."
        pushd ../metalsmith
        bash provision.sh $STACK
        popd
    fi
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing after deployment attempt. Going to retry once."
        pushd ../metalsmith
        bash undeploy_failures.sh
        bash provision.sh $STACK
        popd
        if [[ ! -e $METAL ]]; then
            echo "$METAL is still missing. Aborting."
            exit 1
        fi
    fi
    echo "Finished with baremetal"
fi
if [[ ! -e deployed-metal-$STACK.yaml && $NEW_SPEC -eq 0 ]]; then
    cp $METAL deployed-metal-$STACK.yaml
    cp $NET deployed-network-$STACK.yaml
    cp $VIP deployed-vips-$STACK.yaml
fi

# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
        cp -r /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    if [[ $NODE_COUNT -gt 0 ]]; then
        FOUND_COUNT=$(metalsmith -f value -c "Hostname" list | wc -l)
        if [[ $NODE_COUNT != $FOUND_COUNT ]]; then
            echo "Expecting $NODE_COUNT nodes but $FOUND_COUNT nodes have been deployed"
            exit 1
        fi
    fi

    HEAT_POD=quay.io/tripleomaster/openstack-heat-all:current-tripleo
    podman pull $HEAT_POD

    #export THT=/usr/share/openstack-tripleo-heat-templates
    export THT=/home/stack/templates/
    
    echo "Runing openstack overcloud deploy"
    # Use this as needed to speed up stack updates
    # --disable-container-prepare \
    
    time openstack overcloud deploy \
         --templates $THT \
         --stack $STACK \
         --timeout 90 \
         --libvirt-type qemu \
         --heat-type pod --skip-heat-pull \
         --heat-container-engine-image $HEAT_POD \
         --heat-container-api-image $HEAT_POD \
         -e $THT/environments/network-environment.yaml \
         -e $THT/environments/low-memory-usage.yaml \
         -e $THT/environments/podman.yaml \
         -e $THT/environments/docker-ha.yaml \
         -e $THT/environments/cephadm/cephadm.yaml \
         -r ~/oc0-role-data.yaml \
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
         -e cephadm-overrides.yaml

    # park ceph-ansible options here
    #     -e $THT/environments/ceph-ansible/ceph-ansible.yaml \
    #     -e $THT/environments/disable-swift.yaml \
    #     -e ceph-ansible-overrides.yaml \

fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    pushd $DIR
    bash ansible-playbook-command.sh
    # bash ansible-playbook-command.sh --skip-tags run_ceph_ansible
    popd
fi
