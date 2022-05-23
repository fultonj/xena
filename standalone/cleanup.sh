#!/usr/bin/env bash

FILES=0
CEPH=1
STACK=0
FAKE_DISK=1
REAL_DISK=0
NET=1

if [ $FILES -eq 1 ]; then
    rm -f -v ceph_spec.yaml
    rm -f -v deployed_ceph.yaml
    rm -f -v cirros*
    rm -f -v standalone_parameters.yaml
    sudo rm -f -v /home/ceph-admin/assimilate_ceph.conf
    sudo rm -f -v /home/ceph-admin/specs/*
fi

if [ $CEPH -eq 1 ]; then
    echo "Tearing down Ceph environment"

    # Stop the Ceph service
    FSID=$(sudo ls /var/lib/ceph/ | head -1)
    sudo systemctl stop ceph-osd@*
    # sudo /usr/sbin/cephadm zap-osds --force --fsid $FSID
    sudo /usr/sbin/cephadm rm-cluster --force --fsid $FSID

    # remove ceph container image
    # for IMG in $(sudo podman images \
        #                   --format "{{.ID}} {{.Repository}}" \
        #                  | grep ceph | awk {'print $1'} ); do
    #     sudo podman rmi $IMG;
    # done

    # remove ceph directories
    sudo rm -rf \
         /var/log/ceph \
         /var/run/ceph \
         /var/lib/ceph \
         /run/ceph \
         /etc/ceph/*
fi

if [ $STACK -eq 1 ]; then
    # remove the secret key of the openstack client from libvirt
    for pkg in libvirt-client; do
        rpm -q $pkg > /dev/null
        if [[ $? -ne 0 ]]; then
            sudo dnf install -y libvirt-client
        fi
    done
    for S in $(sudo virsh -q secret-list | awk {'print $1'}); do
        sudo virsh secret-undefine $S
    done
    sudo find / -name secret.xml -exec rm -f {} \; 2> /dev/null


    echo "Tearing down TripleO environment"
    if type pcs &> /dev/null; then
        sudo pcs cluster destroy --force
    fi
    if type podman &> /dev/null; then
        echo "Removing podman containers and images (takes times...)"
        sudo podman rm -af
        sudo podman rmi -af
    fi
    sudo rm -rf \
         /var/lib/tripleo-config \
         /var/lib/config-data /var/lib/container-config-scripts \
         /var/lib/container-puppet \
         /var/lib/heat-config \
         /var/lib/image-serve \
         /var/lib/containers \
         /etc/systemd/system/tripleo* \
         /var/lib/mysql/*
    sudo systemctl daemon-reload

    rm -fv standalone_parameters.yaml
fi

if [ $FAKE_DISK -eq 1 ]; then
    sudo lvremove --force /dev/vg2/db-lv2
    sudo lvremove --force --force /dev/vg2/data-lv2
    sudo vgremove --force --force vg2
    sudo pvremove --force --force /dev/loop3
    sudo losetup -d /dev/loop3
    sudo rm -f /var/lib/ceph-osd.img
    sudo partprobe

    bash disks.sh
    lsblk
fi

if [ $REAL_DISK -eq 1 ]; then
    sudo lvdisplay  | grep "LV PATH" | grep osd | awk {'print $3'} > /tmp/lvs
    sudo chmod 666 /tmp/lvs
    for LV in $(cat /tmp/lvs); do
        sudo lvremove --yes --force --force $LV
    done
    sudo vgdisplay  | grep "VG NAME" | grep osd | awk {'print $3'} > /tmp/vgs
    sudo chmod 666 /tmp/vgs
    for VG in $(cat /tmp/vgs); do
        sudo lvremove --yes --force --force $VG
    done
    sudo pvremove --yes --force --force /dev/vd{b,c,d,e,f}

    sudo dmsetup ls | awk {'print $1'} | grep ceph > /tmp/dms
    sudo chmod 666 /tmp/dms
    for DM in $(cat /tmp/dms); do
        sudo dmsetup remove $DM;
    done
    sudo sgdisk -Z /dev/vd{b,c,d,e,f}
fi

if [ $NET -eq 1 ]; then
    sudo ip link set ceph-dummy0 down
    sudo ip link delete ceph-dummy0 type dummy
fi
