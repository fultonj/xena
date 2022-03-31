#!/bin/bash

source ~/stackrc

metalsmith -f value -c State -c "Node Name" list > /tmp/results

TOTAL=$(cat /tmp/results | wc -l)
ERR=$(grep ERROR /tmp/results | wc -l)
ACT=$(grep ACTIVE /tmp/results | wc -l)

echo "Total: $TOTAL | Deployed: $ACT | Failed: $ERR"

I=0
for NAME in $(grep ERROR /tmp/results | awk {'print $1'}); do
    echo "Undeploying $NAME"
    metalsmith undeploy $NAME
    I=$(($I+1))
    echo "Scheduled $I of $ERR"
done
sleep 2
echo "Current state per metalsmith"
metalsmith list

echo "Checking 'openstack baremetal node list' for failures"

openstack baremetal node list -c Name -c "Provisioning State" -f value \
          > /tmp/results 2> /dev/null
if [[ $(grep failed /tmp/results | wc -l ) -gt 0 ]]; then
    echo "Unfortunately lower level issues require the following:"
fi
for NAME in $(grep failed /tmp/results | awk {'print $1'}); do
    echo "  openstack baremetal node maintenance set $NAME"
    echo "  openstack baremetal node delete $NAME"
done
if [[ $(grep failed /tmp/results | wc -l ) -gt 0 ]]; then
    echo "  bash ~/tripleo_overcloud_node_import.sh"
    exit 1
else
    echo "Try to deploy again"
    exit 0
fi
