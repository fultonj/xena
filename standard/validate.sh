#!/usr/bin/env bash

OVERALL=1
KEYS=0
MDS=0
GLANCE=1
CINDER=1
NOVA=0

STACK=overcloud-0
# STACK=standard-3
INV=~/overcloud-deploy/$STACK/config-download/$STACK/tripleo-ansible-inventory.yaml
RC=/home/stack/${STACK}rc
CEPHADM=1

function run_on_mon {
    if [ $CEPHADM -eq 1 ]; then
        # even this won't work as the container doesn't have the keyring
        # FSID=$(grep fsid /etc/ceph/ceph.conf | awk {'print $3'})
        # podman exec -ti ceph-$FSID-mon.$(hostname) /bin/bash
        CMD="cephadm shell -- $1"
    else
        CMD="podman exec ceph-mon-\$HOSTNAME $1"
    fi
    ansible --private-key /home/stack/.ssh/id_rsa_tripleo -i $INV mons[0] -b -m shell -a "$CMD"
}

source $RC

if [ $OVERALL -eq 1 ]; then
    echo " --------- enabled overcloud services --------- "
    openstack endpoint list -c "Service Name" -f value
    echo " --------- ceph -s --------- "
    run_on_mon "ceph -s"
    echo " --------- ceph df --------- "
    run_on_mon "ceph df"
    # echo " --------- ceph auth list --------- "
    # run_on_mon "ceph auth list"
fi

if [ $KEYS -eq 1 ]; then
    DST=/var/lib/tripleo-config/ceph
    ansible -i $INV Controller,Compute -b -m shell -a "ls -l /etc/ceph"
    ansible -i $INV Controller,Compute -b -m shell -a "ls -l $DST"
    ansible -i $INV Controller,Compute -b -m shell -a "cat $DST/ceph.conf"
    ansible -i $INV Controller,Compute -b -m shell -a "cat $DST/ceph.client.openstack.keyring"
fi

if [ $MDS -eq 1 ]; then
    echo " --------- Ceph MDS --------- "
    run_on_mon "ceph mds stat"
    run_on_mon "ceph fs dump"
fi

if [ $GLANCE -eq 1 ]; then
    # make sure the glance HTTP service is available
    glance_endpoint=$(openstack endpoint list -f value -c "Service Name" -c "Interface" -c "URL" | grep glance | grep public | awk {'print $3'})
    if [[ $(curl -s $glance_endpoint | grep Unavailable | wc -l) -gt 0 ]]; then
        echo "curl $glance_endpoint returns unavailable (glance broken?)"
        curl -s $glance_endpoint
        exit 1
    fi

    img=cirros-0.4.0-x86_64-disk.img
    raw=$(echo $img | sed s/img/raw/g)
    url=http://download.cirros-cloud.net/0.4.0/$img
    if [ ! -f $raw ]; then
	if [ ! -f $img ]; then
	    echo "Could not find qemu image $img; downloading a copy."
	    curl -L -# $url > $img
	fi
	echo "Could not find raw image $raw; converting."
        if [[ ! -e /bin/qemu-img ]]; then
            sudo yum install qemu-img -y
        fi
	qemu-img convert -f qcow2 -O raw $img $raw
    fi

    echo " --------- Ceph images pool --------- "
    echo "Listing Glance Ceph Pool and Image List"
    run_on_mon "rbd -p images ls -l"
    openstack image list

    echo "Importing $raw image into Glance"
    openstack image create cirros --disk-format=raw --container-format=bare < $raw
    if [ ! $? -eq 0 ]; then 
        echo "Could not import $raw image. Aborting"; 
        exit 1;
    fi

    echo "Listing Glance Ceph Pool and Image List"
    run_on_mon "rbd -p images ls -l"
    openstack image list
fi

if [ $CINDER -eq 1 ]; then
    echo " --------- Ceph cinder volumes pool --------- "
    run_on_mon "rbd -p volumes ls -l"
    openstack volume list

    echo "Creating 1 GB Cinder volume"
    openstack volume create --size 1 test-volume
    sleep 10

    echo "Listing Cinder Ceph Pool and Volume List"
    openstack volume list
    run_on_mon "rbd -p volumes ls -l"
fi

if [ $NOVA -eq 1 ]; then
    DEMO_CIDR="172.16.66.0/24"
    openstack network create private_network
    netid=$(openstack network list | awk "/private_network/ { print \$2 }")
    openstack subnet create --network private_network --subnet-range ${DEMO_CIDR} private_subnet
    subid=$(openstack subnet list | awk "/private_subnet/ {print \$2}")
    openstack router create router1
    openstack router add subnet router1 $subid

    openstack flavor create --ram 512 --disk 1 --ephemeral 0 --vcpus 1 --public m1.tiny
    openstack keypair create demokp > ~/demokp.pem 
    chmod 600 ~/demokp.pem

    openstack server create --flavor m1.tiny --image cirros --key-name demokp inst1 --nic net-id=$netid
    openstack server list
    if [[ $(openstack server list -c Status -f value) == "BUILD" ]]; then
        echo "Waiting one minute for building server to boot"
        sleep 60
        openstack server list
    fi
fi
