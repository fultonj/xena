#!/bin/bash

mkdir -p ~/.config/openstack
sudo cp /etc/openstack/clouds.yaml ~/.config/openstack
sudo chown $USER: ~/.config/openstack/clouds.yaml

export OS_CLOUD=overcloud
openstack endpoint list
