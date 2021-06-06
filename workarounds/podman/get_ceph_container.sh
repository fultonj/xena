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
DEV=0

if [[ ! -e ~/containers-prepare-parameter.yaml ]]; then
    echo "containers-prepare-parameter.yaml is missing. Fail."
    exit 1
fi

if [[ $OVERWRITE -eq 1 ]]; then
    if [[ -e ~/re-generated-container-prepare.yaml ]]; then
        rm -v ~/re-generated-container-prepare.yaml
    fi
fi

if [[ DEV -eq 1 ]]; then
    if [[ ! -e ~/containers-prepare-parameter.yaml.nondev ]]; then
        cp -v ~/containers-prepare-parameter.yaml ~/containers-prepare-parameter.yaml.nondev
    fi
    OLD=$(grep ceph_tag ~/containers-prepare-parameter.yaml | awk {'print $2'})
    NEW=v6.0.0-stable-6.0-pacific-centos-8-x86_64
    sed -i -e s/$OLD/$NEW/g ~/containers-prepare-parameter.yaml
    # OLD: ceph_tag: v6.0.0-stable-6.0-pacific-centos-8-x86_64
    # NEW: ceph_tag: latest-pacific-devel
fi

echo "Ceph container:"
grep ceph_ ~/containers-prepare-parameter.yaml \
    | egrep -v "alert|grafana|prometheus|exporter"

openstack tripleo container image prepare \
   --environment-file ~/containers-prepare-parameter.yaml \
   --roles-file /usr/share/openstack-tripleo-heat-templates/roles_data.yaml \
   --output-env-file /home/stack/re-generated-container-prepare.yaml \
   --log-file /home/stack/tripleo-image-prepare-ceph.log

grep ContainerCephDaemonImage /home/stack/re-generated-container-prepare.yaml
