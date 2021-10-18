# directord hackfest

There are my notes for the tripleo-directord-hackfest:

 https://etherpad.opendev.org/p/tripleo-directord-hackfest

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
- [ceph.sh](ceph.sh) calls [ceph.yaml](ceph.yaml) to attempt a
  directord ceph deployment

## Configure task-core and deploy OpenStack

- cd task-core
- ./[install.sh](task-core/install.sh)
- ./[deploy.sh](task-core/deploy.sh)
- ./[ceph.sh](task-core/ceph.sh)

Next I'll try adding a ceph service (add it's supporting services) 
to [my fork of task-core](https://github.com/fultonj/task-core)
which is called by [ceph.sh](task-core/ceph.sh).