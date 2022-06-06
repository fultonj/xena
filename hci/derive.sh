#!/bin/bash

source ~/stackrc

openstack service list
if [[ $? -gt 0 ]]; then
    echo "Cannot Derive Parameters:"
    echo "- Keystone is not running on the undercloud (new Xena default)"
    echo "- Maybe add 'enable_keystone=true' to undercloud.conf?"
    echo "- Otherwise tripleo_get_introspected_data ansible module won't work"
    # https://specs.openstack.org/openstack/tripleo-specs/specs/xena/keystoneless-undercloud.html
    # https://review.opendev.org/c/openstack/python-tripleoclient/+/799409
    # https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/ansible_plugins/modules/tripleo_get_introspected_data.py#L71-L73
    exit 1
fi

INTROSPECTION_LIST=$(openstack baremetal introspection list -f json)
if [[ $INTROSPECTION_LIST == '[]' ]]; then
    echo "Nodes have not been introspected."
    exit 1
fi

UUID=$(openstack baremetal node show oc0-ceph-0 -f value -c uuid)

if [[ ! -e derive-local-hci-parameters.yml ]]; then
    cp -v /usr/share/ansible/tripleo-playbooks/derive-local-hci-parameters.yml .
    sed -i '/UUID/d' derive-local-hci-parameters.yml
fi

ansible-playbook derive-local-hci-parameters.yml \
                 -vvv \
                 -e ironic_node_id=$UUID \
                 -e heat_environment_input_file=overrides.yaml
