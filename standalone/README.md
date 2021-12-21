# Standalone on VM from virsh

[Optional] I make my centos-stream8 VM on a hypervisor by running
- [./centos.sh](https://github.com/fultonj/tripleo-laptop/blob/master/centos.sh)
- [./clone.sh standalone](https://github.com/fultonj/tripleo-laptop/blob/master/clone.sh)

On new standalone VM run:
- [pre.sh](pre.sh)
- [disks.sh](disks.sh)
- [ceph.sh](ceph.sh)
- [deploy.sh](deploy.sh)
- [verify.sh](verify.sh)
- [cleanup.sh](cleanup.sh)

The above is in an evolution from from having deploy.sh deploy ceph
with the overcloud to using deployed ceph.

## Deployed Ceph for standalone

The above standalone deployment works without deployed Ceph.
I tried to switch it to a deployed ceph deployment and had mixed
results. I think the whole thing could be made to work with some
changes in tripleo itself. I encountered the following issues.

### Mock Metalsmith Output

Metalsmith has not been run but `openstack overcloud ceph deploy`
requires a deployed_metal.yaml file. It then looks in the working
dir for the inventory metalsmith created. I was able to trick it
by creating my own versions of these files which we could provide.

- [fake_workdir/deployed_metal.yaml](fake_workdir/deployed_metal.yaml)
- [fake_workdir/tripleo-ansible-inventory.yaml](fake_workdir/tripleo-ansible-inventory.yaml)

Note in the inventory that I also provided network files.

The ansible module will consume the above files and produce a valid
ceph spec as seen in [ceph.sh](ceph.sh) in the SPEC section. As per
the issues described below I opted to then modify this file and keep
my own version instead of generating it dynamically.

I will look into making the deployed_metal.yaml file optional in
cases where a ceph_spec.yaml and inventory are directly provided.

### Network

TripleO standalone needs to configure the 192.168.24.0/24 network
and interface so it doesn't exist yet to use with deployed ceph.

Any VM being deployed by standalone should have its own IP so
I have deployed ceph use that IP, which is the following in my case 
by setting this variable in my inventory (today):

```
tripleo_cephadm_first_mon_ip: 192.168.122.252
```

I'll probably add a --first-mon-ip option to the CLI which overrides
the same.

I also pass a [network_data.yaml](fake_workdir/network_data.yaml) file
which satisfies 
[deployed ceph's need for a --network-data file](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_ceph.html#network-options)
in order to define the tripleo-storage/ceph-public_network and 
tripleo-storage_mgmt/ceph-cluster_network while also overriding the
TripleO default to use the control-plane network since it does
not yet exist. These networks are both set to 0.0.0.0/0 so that
the ceph services listen everywhere which is sufficient for
standalone. This also satisfies cephadm.

I found that the export code did the right thing with that and I know
my VM can reach that network.

```
[stack@standalone standalone]$ sudo cat ~/standalone-ansible-07yaec1q/cephadm/ceph_client.yml
---
tripleo_ceph_client_fsid: fa37898b-a7ac-5d7e-865f-8a56cb2576a7
tripleo_ceph_client_cluster: ceph
external_cluster_mon_ips: "[v2:192.168.122.252:3300/0,v1:192.168.122.252:6789/0]"
keys:
- name: client.openstack
  key: AQBpJmdhAAAAABAAG3pEbYTQo2x/eZh16lSYyA==
  caps:
    mgr: allow *
    mon: profile rbd
    osd: profile rbd pool=vms, profile rbd pool=volumes, profile rbd pool=images
[stack@standalone standalone]$
```

### Hanging Tasks

These tasks were hanging. I haven't looked into why. I did a quick
workaround by simply removing them.

- https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/playbooks/cephadm.yml#L98-L101
- https://github.com/openstack/tripleo-ansible/blob/master/tripleo_ansible/roles/tripleo_cephadm/tasks/pools.yaml#L43-L58

I also deploy with
`~/templates/environments/cephadm/cephadm-rbd-only.yaml` since the RGW
spec application task was hanging.
