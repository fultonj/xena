#!/bin/bash

NODES="oc0-ceph-0 oc0-ceph-1 oc0-ceph-2"

# Need to delete nodes to get them out of "deploy failed"
# Can only delete if they are in maintenance first.
# https://docs.openstack.org/ironic/latest/_images/states.svg
source ~/stackrc
for NODE in $NODES; do
  openstack baremetal node maintenance set $NODE;
  openstack baremetal node delete $NODE;
done

# Reimport them
bash ~/tripleo_overcloud_node_import.sh

# Set them to available
for NODE in $NODES; do
    openstack baremetal node provide $NODE;
done
