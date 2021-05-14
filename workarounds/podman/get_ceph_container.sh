#!/bin/bash
# 
# Serve the ceph octopus container from undercloud
# 
# This script is a workaround until this merges:
#  https://review.opendev.org/77142
# 
# ceph_namespace: quay.ceph.io/ceph-ci
# ceph_image: daemon
# ceph_tag: v5.0.6-stable-5.0-octopus-centos-8-x86_64
# 
# - imagename: quay.ceph.io/ceph-ci/daemon:v5.0.6-stable-5.0-octopus-centos-8-x86_64
#   image_source: ceph
# 
# It is better to mirror and serve this contianer from the undercloud than
# it is to have cephadm download  docker.io/ceph/ceph:v15  for each node.

OVERWRITE=1

if [[ ! -e ~/containers-prepare-parameter.yaml ]]; then
    echo "containers-prepare-parameter.yaml is missing. Fail."
    exit 1
fi

if [[ $OVERWRITE -eq 1 ]]; then
    if [[ -e ~/re-generated-container-prepare.yaml ]]; then
        rm -v ~/re-generated-container-prepare.yaml
    fi
fi

openstack tripleo container image prepare \
   --environment-file ~/containers-prepare-parameter.yaml \
   --roles-file /usr/share/openstack-tripleo-heat-templates/roles_data.yaml \
   --output-env-file /home/stack/re-generated-container-prepare.yaml \
   --log-file /home/stack/tripleo-image-prepare-ceph.log

grep ContainerCephDaemonImage /home/stack/re-generated-container-prepare.yaml
