#!/bin/bash

POD=1
REPO=1
CEPH=1
INSTALL=1
CONTAINERS=1
HOSTNAME=1
DNS=1
EXTRAS=0
TMATE=0

CENT9=$(grep 9 /etc/redhat-release | wc -l)
CENT8=$(grep 8 /etc/redhat-release | wc -l)

if [[ $POD -eq 1 ]]; then
    if [[ $CENT8 -eq 1 ]]; then
        sudo dnf module enable -y container-tools:3.0
    fi
    sudo dnf install -y podman 
fi

if [[ $REPO -eq 1 ]]; then
    if [[ ! -d ~/rpms ]]; then mkdir ~/rpms; fi
    if [[ $CENT8 -eq 1 ]]; then
        url=https://trunk.rdoproject.org/centos8/component/tripleo/current/
    fi
    if [[ $CENT9 -eq 1 ]]; then
        url=https://trunk.rdoproject.org/centos9/component/tripleo/current/
    fi
    rpm_name=$(curl $url | grep python3-tripleo-repos | sed -e 's/<[^>]*>//g' | awk 'BEGIN { FS = ".rpm" } ; { print $1 }')
    rpm=$rpm_name.rpm
    curl -f $url/$rpm -o ~/rpms/$rpm
    if [[ -f ~/rpms/$rpm ]]; then
	sudo yum install -y ~/rpms/$rpm
	sudo -E tripleo-repos current-tripleo-dev ceph --stream
	sudo yum repolist
	sudo yum update -y
    else
	echo "$rpm is missing. Aborting."
	exit 1
    fi
fi

if [[ $CEPH -eq 1 ]]; then
    sudo dnf install -y cephadm util-linux lvm2
    CEPHADMSRC=0
    if [[ $CEPHADMSRC -eq 1 ]]; then
        CEPHADM_PATH=/usr/sbin/cephadm
        CEPHADM_SRC=https://raw.githubusercontent.com/ceph/ceph/pacific/src/cephadm/cephadm
        md5sum $CEPHADM_PATH
        curl --remote-name --location --insecure $CEPHADM_SRC -o cephadm
        sudo mv cephadm $CEPHADM_PATH
        md5sum $CEPHADM_PATH
        sudo chown root:root $CEPHADM_PATH
        sudo chmod 755 $CEPHADM_PATH
    fi
fi

if [[ $INSTALL -eq 1 ]]; then
    sudo yum install -y python3-tripleoclient
fi

if [[ $CONTAINERS -eq 1 ]]; then
    openstack tripleo container image prepare default \
      --output-env-file $HOME/containers-prepare-parameters.yaml
fi

if [[ $HOSTNAME -eq 1 ]]; then
    sudo setenforce 0
    sudo hostnamectl set-hostname standalone.localdomain
    sudo hostnamectl set-hostname standalone.localdomain --transient
    sudo setenforce 1
    IP=$(ip a s eth1 | grep inet | grep 192 | awk {'print $2'} | sed s/\\/24//)
    sudo sed -i "/$IP/d" /etc/hosts
    sudo sh -c "echo $IP standalone.localdomain standalone>> /etc/hosts"
fi

if [[ $DNS -eq 1 ]]; then
    GW=192.168.122.1
    sudo sysctl -w net.ipv4.ping_group_range="0 1000"
    ping -c 1 $GW > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "Cannot ping $GW. Aborting."
        exit 1
    fi
    if [[ $(grep $GW /etc/resolv.conf | wc -l) -eq 0 ]]; then
        sudo sh -c "echo nameserver $GW > /etc/resolv.conf"
    fi
fi

if [[ $EXTRAS -eq 1 ]]; then
    sudo dnf install -y tmux emacs-nox vim
fi

if [[ $TMATE -eq 1 ]]; then
    TMATE_RELEASE=2.4.0
    curl -OL https://github.com/tmate-io/tmate/releases/download/$TMATE_RELEASE/tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz /usr/src/
    pushd /usr/src/
    sudo tar xf tmate-$TMATE_RELEASE-static-linux-amd64.tar.xz
    sudo mv /usr/src/tmate-$TMATE_RELEASE-static-linux-amd64/tmate /usr/local/bin/tmate
    sudo chmod 755 /usr/local/bin/tmate
    popd
fi
