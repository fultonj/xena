#!/bin/bash

BUILD=1
PULL=1
BOUNCE=1

if [[ $BUILD -eq 1 ]]; then
    time sudo openstack tripleo container image prepare \
         -e prepare.yaml \
         --output-env-file ~/containers-env-file-heat-patch.yaml
fi

if [[ $PULL -eq 1 ]]; then
    NEW_IMG=$(grep ContainerHeatEngineImage ~/containers-env-file-heat-patch.yaml |\
                  awk {'print $2'} | sed s/.mydomain.tld//g )
    sudo podman pull $NEW_IMG
    sudo podman images | grep heat-engine
fi

if [[ $BOUNCE -eq 1 ]]; then
    sudo podman ps | grep heat-engine
    ansible-playbook heat_container_manage.yml
    sudo podman ps | grep heat-engine
fi
