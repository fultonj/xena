#!/bin/bash
# Does what's described in this BZ for $1
# https://bugzilla.redhat.com/show_bug.cgi?id=1613918

if [ $# -eq 0 ]; then
    echo "USAGE: $0 <NODE> (where <NODE> is like oc0-ceph-3)"
    exit 1
fi

source ~/stackrc
UUID=$(openstack baremetal node show $1 -f value -c uuid \
       | egrep "\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b")

if [[ -z $UUID ]]; then
    echo "unable to get a valid UUID for $1"
    exit 1
else
    echo "Found $UUID for $1"
fi

SLEEP=5
RETRY=3
i=0
while [ 1 ]; do
    i=$(($i+1)); 
    STATE=$(openstack baremetal node show $UUID -f value -c provision_state)
    if [[ $STATE != "available" ]]; then
        echo "Node $1 is in state: $STATE . Unable to mark it as manageable for cleaning."
        if [[ $i -gt $RETRY ]]; then
            echo "Retries exhausted. Giving up."
            exit 1
        fi;
        echo "Sleeping $SLEEP seconds and then trying again (attempt $i of $RETRY)"
        sleep $SLEEP
    else
        break
    fi
done

openstack baremetal node manage $UUID
openstack baremetal node clean $UUID --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'

echo "Waiting for $1 to finish cleaning..."
i=0
while [ 1 ]; do
    STATE=$(openstack baremetal node show $UUID -f value -c provision_state)
    if [[ $STATE == "manageable" || $STATE == "clean failed" ]]; then
        break;
    else
        echo -n "."
        sleep 5
        i=$(($i+1))
    fi
    if [[ $i -gt 60 ]]; then # 5 minutes
        echo "Node $1 is in state: $STATE"
        echo "Giving up after $(($i * 5)) seconds"
        exit 1
    fi
done

if [[ $STATE == "manageable" ]]; then
    echo "Node $1 is in state: $STATE . Marking it as available."
    openstack baremetal node provide $UUID
fi
