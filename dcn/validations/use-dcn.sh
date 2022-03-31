#!/usr/bin/env bash

AZ="dcn0"

SHOWAZ=1
NOVA=1
DEPS=1
CINDER=1
PUBLIC=0
SCALEOUT=1

IMAGE=cirros

RC=~/control-planerc
if [[ ! -e $RC ]]; then
    echo "$RC is missing. Aborting."
    exit 1
fi
source $RC

openstack image show $IMAGE
if [[ $? != 0 ]]; then
    echo "Unable to find Glance image: $IMAGE . Aborting."
    exit 1
fi

openstack endpoint list > /dev/null
if [[ $? -gt 0 ]]; then
    echo "Cannot list end points. Aborting"
    exit 1
fi

export PRIVATE_NETWORK_CIDR=192.168.200.0/24
if [[ $PUBLIC -eq 1 ]]; then
    export PUBLIC_NETWORK_CIDR=192.168.24.0/24
    export GATEWAY=192.168.24.1
    export PUBLIC_NET_START=192.168.24.40
    export PUBLIC_NET_END=192.168.24.50
fi

if [[ $SCALEOUT -eq 1 ]]; then
    #NODE="${AZ}-distributedcomputehci-0.localdomain"
    NODE=oc0-ceph-2.mydomain.tld
    echo "The SCALEOUT=1 option is enabled, removing $NODE from nova scheduler"
    # openstack compute service list
    openstack compute service set $NODE nova-compute --disable
    openstack compute service list
    echo "Nova test will only be run on the DistributedComputeHCIScaleOut node"
fi

if [[ $SHOWAZ -eq 1 ]]; then
    echo "Show aggregates for $AZ"
    openstack aggregate show $AZ
    echo "Compute availability zones"
    openstack availability zone list --compute
    nova availability-zone-list

    echo "Volume services"
    openstack volume service list
    echo "Volume availability zones"
    openstack availability zone list --volume
fi

# if [[ $MKAZ -eq 1 ]]; then
#     No longer needed as owalsh's tripleo changes take care of this
#     # MKAZ=0
#     # export HOST_AGGREGATE="HA-${AZ}"
#     # Create host aggregate and AZ
#     # unnecessary if undercloud can reach endpoints and deployed with nova-az.yaml
#     if ! openstack aggregate show $HOST_AGGREGATE >null 2>&1; then
#         echo "Creating a host aggregate for $AZ"
#         openstack aggregate create $HOST_AGGREGATE --zone $AZ
#         for H in $(openstack hypervisor list -f value -c "Hypervisor Hostname" | grep $AZ); do
#             echo "Adding $H to $HOST_AGGREGATE"
#             openstack aggregate add host $HOST_AGGREGATE $H
#         done
#     else
#         echo "Host Aggregate: $HOST_AGGREGATE"
#         openstack aggregate show $HOST_AGGREGATE
#     fi
#     echo "Compute availability zones (after change)"
#     openstack availability zone list --compute
#     nova availability-zone-list

#     echo "Volume services"
#     openstack volume service list
#     echo "Volume availability zones"
#     openstack availability zone list --volume
# fi

if [[ $NOVA -eq 1 ]]; then
    if [[ $DEPS -eq 1 ]]; then
        echo "Checking the following dependencies..."
        IMAGE_ID=$(openstack image show $IMAGE -f value -c id)
        if [[ -z $IMAGE_ID ]]; then
            echo "Unable to find $IMAGE image (see use-multistore-glance.sh)"
            exit 1
        fi
        echo "- glance image"
        # create basic security group to allow ssh/ping/dns only if necessary
        SEC_GROUP_ID=$(openstack security group show basic -f value -c id)
        if [[ -z $SEC_GROUP_ID ]]; then
            openstack security group create basic
            # allow ssh
            openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
            # allow ping
            openstack security group rule create --protocol icmp basic
            # allow DNS
            openstack security group rule create --protocol udp --dst-port 53:53 basic
        fi
        echo "- security groups"
        # create public/private networks only if necessary
        if [[ $PUBLIC -eq 1 ]]; then
            PUB_NET_ID=$(openstack network show public-${AZ} -c id -f value)
            if [[ -z $PUB_NET_ID ]]; then
                openstack network create --external --provider-physical-network datacentre --provider-network-type flat public
            fi
            PUB_SUBNET_ID=$(openstack network show public-${AZ} -c subnets -f value)
            if [[ -z $PUB_SUBNET_ID ]]; then
                openstack subnet create public-net-${AZ} \
                          --subnet-range $PUBLIC_NETWORK_CIDR \
                          --no-dhcp \
                          --gateway $GATEWAY \
                          --allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
                          --network public-${AZ}
            fi
            echo "- public networks"
        fi
        PRI_NET_ID=$(openstack network show private-${AZ} -c id -f value)
        if [[ -z $PRI_NET_ID ]]; then
            openstack network create --internal private-${AZ}
        fi
        PRI_SUBNET_ID=$(openstack network show private-${AZ} -c subnets -f value)
        if [[ $PRI_SUBNET_ID == '[]' ]]; then
            openstack subnet create private-net-${AZ} \
                      --subnet-range $PRIVATE_NETWORK_CIDR \
                      --network private-${AZ}
        fi
        echo "- private networks"
        # create router only if necessary
        if [[ $PUBLIC -eq 1 ]]; then        
            ROUTER_ID=$(openstack router show vrouter-${AZ} -f value -c id)
            if [[ -z $ROUTER_ID ]]; then
                # IP will be automatically assigned from allocation pool of the subnet
                openstack router create vrouter-${AZ}
                openstack router set vrouter-${AZ} --external-gateway public-${AZ}
                openstack router add subnet vrouter-${AZ} private-net-${AZ}
            fi
            echo "- router"
            # create floating IP only if necessary
            FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
            if [[ -z $FLOATING_IP ]]; then
                openstack floating ip create public-${AZ}
                FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
            fi
            if [[ -z $FLOATING_IP ]]; then
                echo "Unable to use existing or create new floating IP"
                exit 1
            fi
            echo "- floating IP"
        fi    
        # create flavor only if necessary
        FLAVOR_ID=$(openstack flavor show tiny -f value -c id)
        if [[ -z $FLAVOR_ID ]]; then
            openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
        fi
        echo "- flavor"
        KEYPAIR_ID=$(openstack keypair show demokp-${AZ} -f value -c user_id)
        if [[ ! -z $KEYPAIR_ID ]]; then
            openstack keypair delete demokp-${AZ}
            if [[ -f ~/demokp-${AZ}.pem ]]; then
                rm -f ~/demokp-${AZ}.pem
            fi
        fi
        openstack keypair create demokp-${AZ} > ~/demokp-${AZ}.pem
        chmod 600 ~/demokp-${AZ}.pem
        echo "- SSH keypairs"
        echo ""
    fi
    echo "Deleting previous Nova server(s)"
    for ID in $(openstack server list -f value -c ID); do
        openstack server delete $ID;
    done

    if [[ $CINDER -eq 1 ]]; then
        echo "Showing status of cinder A/A cluster(s)"
        cinder --os-volume-api-version 3.11 cluster-list --detail
        cinder --os-volume-api-version 3.11 cluster-show $AZ@tripleo_ceph
        
	# Delete volumes after deleting servers to ensure no volumes are attached.
	echo "Deleting previous Cinder volume(s)"
	for ID in $(openstack volume list -f value -c ID); do
            openstack volume delete $ID;
	done

	echo "Creating Cinder volume"
	openstack volume create --size 1 --availability-zone $AZ myvol-${AZ}
	if [ $? != "0" ]; then
            echo "Error creating a volume in AZ ${AZ}. If this is a brand new dcn"
            echo "deployment then cinder-scheduler may not have time to learn about"
            echo "the new AZ. Please wait minute or so, and try again."
            exit 1
	fi
	for i in {1..5}; do
            sleep 1
            STATUS=$(openstack volume show myvol-${AZ} -f value -c status)
            if [[ $STATUS == "available" || $STATUS == "error" ]]; then
		break
            fi
	done

	if [[ $STATUS != "available" ]]; then
            echo "Volume create failed; aborting."
            exit 1
	fi
    fi

    echo "Launching Nova server"
    openstack server create --flavor tiny --image $IMAGE --key-name demokp-${AZ} --network private-${AZ} --security-group basic myserver-${AZ} --availability-zone $AZ

    STATUS=$(openstack server show myserver-${AZ} -f value -c status)
    echo "Server status: $STATUS (waiting)"
    while [[ $STATUS == "BUILD" ]]; do
        sleep 1
        echo -n "."
        STATUS=$(openstack server show myserver-${AZ} -f value -c status)
    done
    echo ""
    if [[ $STATUS == "ERROR" ]]; then
        echo "Server build failed; aborting."
        exit 1
    fi
    if [[ $STATUS == "ACTIVE" ]]; then
        openstack server list
        if [[ $PUBLIC -eq 1 ]]; then
            FLOATING_IP=$(openstack floating ip list -f value -c "Floating IP Address")
            openstack server add floating ip myserver-${AZ} $FLOATING_IP
            echo "Will attempt to SSH into $FLOATING_IP for 30 seconds"
            i=0
            while true; do
                ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
                    -i ~/demokp-${AZ}.pem cirros@$FLOATING_IP "exit" 2> /dev/null && break
                echo -n "."
                sleep 1
                i=$(($i+1))
                if [[ $i -gt 30 ]]; then break; fi
            done
            echo ""
            ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
                -i ~/demokp-${AZ}.pem cirros@$FLOATING_IP "uname -a; lsblk"
            echo ""
        fi
	if [[ $CINDER -eq 1 ]]; then
            echo "Attaching the volume"
            openstack server add volume myserver-${AZ} myvol-${AZ}
            sleep 3
            openstack volume list
	fi
        if [[ $PUBLIC -eq 1 ]]; then        
            ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
                -i ~/demokp-${AZ}.pem cirros@$FLOATING_IP "uname -a; lsblk"
            echo ""
            echo -e "\nssh -o \"UserKnownHostsFile /dev/null\" -o \"StrictHostKeyChecking no\" -i ~/demokp-${AZ}.pem cirros@$FLOATING_IP"
        fi
    fi
fi

if [[ $SCALEOUT -eq 1 ]]; then
    echo "Adding $NODE back to the nova scheduler"
    # openstack compute service list
    openstack compute service set $NODE nova-compute --enable
    openstack compute service list
fi
