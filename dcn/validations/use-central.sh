#!/usr/bin/env bash

OVERALL=0
CINDER=0
NOVA=1
IMAGE=cirros
#IMAGE=myserver-dcn0-snapshot

RC=~/control-planerc
if [[ ! -e $RC ]]; then
    echo "$RC is missing. Aborting."
    exit 1
fi

# Get MON
source ~/stackrc
metalsmith -f value -c "IP Addresses" -c Hostname list > /tmp/metal
MON=$(grep oc0-controller-0 /tmp/metal | awk 'BEGIN { FS = "=" } ; { print $2 }')

function run_on_mon {
    # since it will be run on the controller
    ssh heat-admin@$MON "sudo cephadm shell --config /etc/ceph/central.conf --keyring /etc/ceph/central.client.admin.keyring -- $1"
}

source $RC

openstack image show $IMAGE
if [[ $? != 0 ]]; then
    echo "Unable to find Glance image: $IMAGE . Aborting."
    exit 1
fi

if [ $OVERALL -eq 1 ]; then
    echo " --------- ceph -s --------- "
    run_on_mon "ceph -s"
    echo " --------- ceph df --------- "
    run_on_mon "ceph df"
    echo " --------- ceph auth list --------- "
    run_on_mon "ceph auth list"
fi

if [ $CINDER -eq 1 ]; then
    echo " --------- Ceph cinder volumes pool --------- "
    run_on_mon "rbd -p volumes ls -l"
    openstack volume list

    echo "Creating 1 GB Cinder volume"
    openstack volume create --size 1 volume_central
    sleep 30 

    echo "Listing Cinder Ceph Pool and Volume List"
    openstack volume list
    run_on_mon "rbd -p volumes ls -l"
fi

if [ $NOVA -eq 1 ]; then
    DEMO_CIDR="172.16.66.0/24"
    openstack network create private_network_central
    netid=$(openstack network list | awk "/private_network_central/ { print \$2 }")
    openstack subnet create --network private_network_central --subnet-range ${DEMO_CIDR} private_subnet_central
    subid=$(openstack subnet list | awk "/private_subnet_central/ {print \$2}")
    openstack router create router_central
    openstack router add subnet router_central $subid

    openstack flavor create --ram 512 --disk 1 --ephemeral 0 --vcpus 1 --public m1.tiny
    openstack keypair create demokp_central > ~/demokp_central.pem 
    chmod 600 ~/demokp_central.pem

    # have not yet created AZs, so specify non-dcn hypervisor
    #HYPERVISOR=$(openstack hypervisor list -f value -c "Hypervisor Hostname" | grep -v dcn)
    HYPERVISOR=oc0-ceph-0.mydomain.tld

    openstack server create --hypervisor-hostname $HYPERVISOR --flavor m1.tiny --image $IMAGE --key-name demokp_central vm_central --nic net-id=$netid

    openstack server list
    if [[ $(openstack server list -c Status -f value) == "BUILD" ]]; then
        echo "Waiting one minute for building server to boot"
        sleep 60
        openstack server list
    fi
fi

