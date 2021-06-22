#!/bin/bash

# GET AN INVENTORY

# PLAY: undercloud,overcloud
# CREATE CEPHADM USER
# - name: Prepare cephadm user and keys
#   include_role:
#     name: tripleo_run_cephadm
#     tasks_from: enable_ceph_admin_user.yml
#
# https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/roles/tripleo_run_cephadm/tasks/enable_ceph_admin_user.yml
#
# https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/playbooks/ceph-admin-user-playbook.yml

# PLAY: localhost
# CREATE SPEC
# - name: genereate ceph_spec for bootstrap
#   ceph_spec_bootstrap:
#     new_ceph_spec: "{{ tripleo_run_cephadm_spec_path }}"
#     tripleo_ansible_inventory: "{{ inventory_file }}"
#     fqdn: "{{ ceph_spec_fqdn }}"
#     osd_spec: "{{ ceph_osd_spec }}"


# PLAY: bootstrap node
# BOOTSTRAP
# - name: Bootstrap Ceph
#   import_role:
#     name: tripleo_cephadm
#     tasks_from: bootstrap

# APPLY SPEC
# - name: Apply Ceph spec
#   import_role:
#     name: tripleo_cephadm
#     tasks_from: apply_spec

# customer crush rules should be set manually via cephadm
