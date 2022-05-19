#!/usr/bin/env bash

CLIENT=0
NET=1
SPEC=1
USER=1
CEPH=1
ANSIBLE=0
CEPH_IP=192.168.42.1

if [ $CLIENT -eq 1 ]; then
    bash ../init/python-tripleoclient.sh
fi

if [ $NET -eq 1 ]; then
    sudo ip link add ceph-dummy0 type dummy
    sudo ip addr add $CEPH_IP/24 dev ceph-dummy0
    sudo ip link set ceph-dummy0 up
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
          --single-host-defaults \
          --mon-ip $CEPH_IP \
          --ceph-spec ceph_spec.yaml \
          --skip-user-create \
          --skip-hosts-config \
          --config initial-ceph.conf \
          --network-data network_data.yaml \
          -y --output deployed_ceph.yaml
fi

if [[ $ANSIBLE -eq 1 ]]; then
    # Use tripleo-operator-ansible to do SPEC USER CEPH
    if [[ ! -e ceph.yaml ]]; then
        echo "ceph.yaml is missing"
        exit 1
    fi
    if [[ ! -d  ~/tripleo-operator-ansible ]]; then
        echo "~/tripleo-operator-ansible is missing"
        exit 1
    fi
    # cp playbook to use relative paths in tripleo-operator-ansible
    cp -v -f ceph.yaml ~/tripleo-operator-ansible/
    pushd ~/tripleo-operator-ansible/
    ansible-playbook \
        --module-path "~/.ansible/plugins/modules/:/usr/share/ansible/plugins/modules:~/tripleo-operator-ansible/plugins/modules/" \
        --extra-vars '{"ansible_env": {"HOME": "/home/stack/"}}' \
        ceph.yaml
    popd
    rm -v -f ~/tripleo-operator-ansible/ceph.yaml
fi
