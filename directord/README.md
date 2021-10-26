# directord hackfest

These are my notes for the tripleo-directord-hackfest:

 https://etherpad.opendev.org/p/tripleo-directord-hackfest

I use these scripts for repeatability but creating them by reading
the above was valuable to learning how to work in directord/task-core.
Thus, I recomend starting by reading the above instead of just running
these scripts if you are trying to learn directord/task-core.

## Environment

[Optional] I make two centos-stream8 VMs on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh node 2](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

I can then do the following:
```
ssh stack@node0
ssh stack@node1
```
On node0:/home/stack/ I'm keeping the contents of this git repository.

## Configure directord for two nodes

- [pre.sh](pre.sh)
- [install.sh](install.sh)
- [bootstrap.sh](bootstrap.sh)
- [chmod.sh](chmod.sh)
- `source /opt/directord/bin/activate`
- `directord manage --list-nodes`

## Configure task-core and deploy OpenStack

- cd task-core
- ./[install.sh](task-core/install.sh)
- ./[deploy.sh](task-core/deploy.sh)
- ./[verify.sh](task-core/verify.sh)

During deployment if you see a certain UUID fail,
run the following to figure out what went wrong:
`directord manage --job-info $UUID`.

## Write your own task-core service

I'm now working on my own
[ssh_user service](https://github.com/fultonj/directord_ceph/blob/main/examples/directord/services/ssh_user.yaml])
with its supporting [files](https://github.com/fultonj/directord_ceph/tree/main/examples/directord/services/files/ssh_user).

I use the following scripts and input files to test my service in the
environment set up by the above (even if the task-core deploy.sh script
has not been run).

- cd [ssh_user](task-core/ssh_user)
- ./[test_ssh_user.sh](task-core/ssh_user/test_ssh_user.sh)

The test_ssh_user.sh script assumes you have your fork of task-core in
the home directory with the branch you are developing. It copies in the
following files before running the task-core command with them.

- [2node_config.yaml](task-core/ssh_user/2node_config.yaml)
Overwrite the default 2node_config.yaml so that the following file is copied in instead
- [task-core-ssh-user.yaml](task-core/ssh_user/task-core-ssh-user.yaml)
Define variables necessary to deploy your service including your service's variables
- [2node_roles_ssh_user.yaml](task-core/ssh_user/2node_roles_ssh_user.yaml)
Map roles to services; include your new service on the role that needs it
- [task-core-inventory-ssh-user.yaml](task-core/ssh_user/task-core-inventory-ssh-user.yaml)
Map nodes to roles

Future developments on this will be done under

 https://github.com/fultonj/directord_ceph
