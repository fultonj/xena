# directord hackfest

There are my notes for the tripleo-directord-hackfest:

 https://etherpad.opendev.org/p/tripleo-directord-hackfest

## Environment

[Optional] I make two centos-stream8 VMs on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh overcloud 2](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

I can then do the following:
```
ssh stack@overcloud0
ssh stack@overcloud1
```
On overcloud0:/home/stack/ I'm keeping the contents of this git repository.

## Configure directord for two nodes

- [pre.sh](pre.sh)
- [install.sh](install.sh)
- [bootstrap.sh](bootstrap.sh)
- [chmod.sh](chmod.sh)
- `source /opt/directord/bin/activate`
- `directord manage --list-nodes`

## Configure task-core

