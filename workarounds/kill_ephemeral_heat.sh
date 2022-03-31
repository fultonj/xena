#!/bin/bash

source ~/stackrc

openstack tripleo launch heat \
  --heat-type pod \
  --heat-dir ~/overcloud-deploy/overcloud/heat-launcher \
  --kill
