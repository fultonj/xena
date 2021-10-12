#!/usr/bin/env bash

TEST=0
PLAY=1
CLI=0

if [[ $TEST -eq 1 ]]; then
    # confirm localhost inventory works
    ansible -i fake_workdir/tripleo-ansible-inventory.yaml -m ping all
    # confirm that ansible module can parse provided inputs
    ansible localhost -m ceph_spec_bootstrap \
      -a "deployed_metalsmith=fake_workdir/deployed_metal.yaml \
          tripleo_roles=/usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml"

    ls -l ~/ceph_spec.yaml 
    cat ~/ceph_spec.yaml
    rm -v ~/ceph_spec.yaml
fi


if [[ $PLAY -eq 1 ]]; then
    PLAYBOOKS="/usr/share/ansible/tripleo-playbooks"
    THT="/usr/share/openstack-tripleo-heat-templates"
    INV="$PWD/fake_workdir/tripleo-ansible-inventory.yaml"
    ansible-playbook -i $INV \
           -v \
           $PLAYBOOKS/cli-deployed-ceph.yaml \
           -e baremetal_deployed_path="$PWD/fake_workdir/deployed_metal.yaml" \
           -e osd_spec_path="$PWD/fake_workdir/osd_spec.yaml" \
           -e deployed_ceph_tht_path="$PWD/deployed_ceph.yaml" \
           -e tripleo_roles_path="$THT/roles/Standalone.yaml" \
           -e tripleo_cephadm_container_image="daemon" \
           -e tripleo_cephadm_container_ns="quay.ceph.io/ceph-ci" \
           -e tripleo_cephadm_container_tag="latest-pacific-devel" \
           -e working_dir="$PWD/fake_workdir" \
           -e storage_network_name="ctlplane" \
           -e storage_mgmt_network_name="ctlplane"
fi


if [[ $CLI -eq 1 ]]; then
    openstack overcloud ceph deploy \
          fake_workdir/deployed_metal.yaml \
          --working-dir fake_workdir \
          --roles-data /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
          --osd-spec fake_workdir/osd_spec.yaml \
          --container-namespace quay.io/ceph \
          --container-image daemon \
          --container-tag v6.0.4-stable-6.0-pacific-centos-8-x86_64 \
          --stack standalone \
          -y -o deployed_ceph.yaml
fi
