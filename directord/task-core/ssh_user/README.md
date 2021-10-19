# SSH User Task Core Service

This service does the following:

- Create a user on all node of the cluster
- Generates a public/private SSH key pair for that user
- Distributes the key pair so the user can SSH to all nodes

This service can take the place of the 
[tripleo-create-admin](https://docs.openstack.org/tripleo-ansible/latest/roles/role-tripleo_create_admin.html)
role from tripleo-ansible.

## Why?

The tripleo-create-admin function won't be necessary for its original
purpose because directord can already bootstrap a cluster with admin
access. However, the Ceph integration in tripleo-ansible 
[uses](https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/playbooks/ceph-admin-user-playbook.yml)
the role because 
[cephadm requires ssh access to all nodes in a ceph cluster](https://docs.ceph.com/en/latest/cephadm/install/#further-information-about-cephadm-bootstrap).
If directord/task-core are going to bootstrap Ceph then
we'll need this feature.

## Testing

This is my first time attempting to write a task-core service.

This directory contains scripts, hooks and input data to set up and
run the service in my environment. The service itself exsits in my 
fork of task-core.
 
  https://github.com/fultonj/task-core/tree/ssh_user

