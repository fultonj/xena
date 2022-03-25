#!/bin/bash

IRONIC=1
CEPH=1
HEAT=0

STACK=dcn0
DIR=~/config-download

source ~/stackrc
# -------------------------------------------------------
METAL="../../metalsmith/deployed-metal-${STACK}.yaml"
NET="../../metalsmith/deployed-network-${STACK}.yaml"
VIP="../../metalsmith/deployed-vips-${STACK}.yaml"
if [[ $IRONIC -eq 1 ]]; then
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing. Deploying nodes with metalsmith."
        pushd ../../metalsmith
        bash provision.sh $STACK
        popd
    fi
    if [[ ! -e $METAL ]]; then
        echo "$METAL is missing after deployment attempt. Going to retry once."
        pushd ../../metalsmith
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
if [[ $CEPH -eq 1 ]]; then
    openstack overcloud ceph deploy \
              $PWD/deployed-metal-$STACK.yaml \
              -y -o $PWD/deployed-ceph-$STACK.yaml \
              --container-image-prepare ~/containers-prepare-parameter.yaml \
              --network-data ~/oc0-network-data.yaml \
              --roles-data dcn_roles.yaml \
              --stack $STACK
fi
# -------------------------------------------------------
if [[ $HEAT -eq 1 ]]; then
    if [[ ! -d ~/templates ]]; then
        ln -s /usr/share/openstack-tripleo-heat-templates ~/templates
    fi
    time openstack overcloud -v deploy \
         --disable-validations \
         --deployed-server \
         --stack $STACK \
         --config-download-timeout 240 \
         --templates ~/templates/ \
         -r dcn_roles.yaml \
         -e ~/templates/environments/deployed-server-environment.yaml \
         -e ~/templates/environments/disable-telemetry.yaml \
         -e ~/templates/environments/low-memory-usage.yaml \
         -e ~/templates/environments/docker-ha.yaml \
         -e ~/templates/environments/podman.yaml \
         -e ~/templates/environments/ceph-ansible/ceph-ansible.yaml \
         -e ~/templates/environments/dcn-storage.yaml \
         -e $CONTAINER_FILE \
         -e ~/oc0-domain.yaml \
         -e $METAL \
         -e ../control-plane-export.yaml \
         -e ../ceph-export-control-plane.yaml \
         -e ceph.yaml \
         -e glance.yaml \
         -e overrides.yaml \
         --libvirt-type qemu

    # network isol
         # -n ../../network-data.yaml \
         # -e ~/templates/environments/deployed-server-environment.yaml \
         # -e ~/templates/environments/network-isolation.yaml \
         # -e ~/templates/environments/network-environment.yaml \
    # no swap
         # -e ~/templates/environments/enable-swap.yaml \
    # make the container list dynamically per stack
    # -e ~/containers-prepare-parameter.yaml \
    # -e ~/re-generated-container-prepare.yaml \
fi

