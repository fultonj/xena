#!/bin/bash

IRONIC=1
HEAT=1
DOWN=0

STACK=overcloud
DIR=/home/stack/overcloud-deploy/$STACK/config-download
NODE_COUNT=7

source ~/stackrc
# -------------------------------------------------------
METAL="../metalsmith/deployed-metal-${STACK}.yaml"
NET="../metalsmith/deployed-network-${STACK}.yaml"
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
fi
if [[ ! -e deployed-metal-$STACK.yaml && $NEW_SPEC -eq 0 ]]; then
    cp $METAL deployed-metal-$STACK.yaml
    cp $NET deployed-network-$STACK.yaml
fi

# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
        ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    if [[ $NODE_COUNT -gt 0 ]]; then
        FOUND_COUNT=$(metalsmith -f value -c "Hostname" list | wc -l)
        if [[ $NODE_COUNT != $FOUND_COUNT ]]; then
            echo "Expecting $NODE_COUNT nodes but $FOUND_COUNT nodes have been deployed"
            exit 1
        fi
    fi
    
    time openstack overcloud deploy \
         --templates ~/templates \
         --stack $STACK \
         --timeout 90 \
         --libvirt-type qemu \
         -e ~/templates/environments/deployed-server-environment.yaml \
         -e deployed-metal-$STACK.yaml \
         -e deployed-network-$STACK.yaml \
         -e ~/templates/environments/network-isolation.yaml \
         -e ~/templates/environments/network-environment.yaml \
         -e ~/templates/environments/disable-telemetry.yaml \
         -e ~/templates/environments/low-memory-usage.yaml \
         -e ~/templates/environments/docker-ha.yaml \
         -e ~/templates/environments/podman.yaml \
         -e ~/templates/environments/cephadm/cephadm.yaml \
         -e ~/containers-prepare-parameter.yaml \
         -e ~/re-generated-container-prepare.yaml \
         -e ~/oc0-domain.yaml \
         --environment-directory ../env_common \
         -e cephadm-overrides.yaml \
         -r ~/oc0-role-data.yaml \
         -n ~/oc0-network-data.yaml \
         --disable-validations --deployed-server

    # park ceph-ansible options here
    #     -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
    #     -e ~/templates/environments/disable-swift.yaml \
    #     -e ceph-ansible-overrides.yaml \

fi
# -------------------------------------------------------
if [[ $DOWN -eq 1 ]]; then
    pushd $DIR
    bash ansible-playbook-command.sh
    # bash ansible-playbook-command.sh --skip-tags run_ceph_ansible
    popd
fi
