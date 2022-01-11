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

### Mock Inputs

#### Spec not Metalsmith

Metalsmith is not run with standalone but
`openstack overcloud ceph deploy` requires a deployed_metal.yaml
file unless we merge
[822726](https://review.opendev.org/c/openstack/python-tripleoclient/+/822726).
That means we need to provide a Ceph spec though. To address that we
genereate this separately using a new command `openstack overcloud
ceph spec`. This will also be consistent with the move to task-core
and further decoupling. For this new command we also add a
`--standalone` option for developers which can be run like the
following to produce a spec file.

```
openstack overcloud ceph spec \
    --first-mon-ip 192.168.122.252 \
    --data-devices osd_spec.yaml
    --standalone
```

#### Ansible

Even without the deployed_metal.yaml file, `openstack overcloud ceph
deploy` still requires an ansible inventory which would normally be
produced by metalsmith. We can have our users create this
directly by providing an example which is generic enough that anyone
can paste it directly from the documentation:
[tripleo-ansible-inventory.yaml](tripleo-ansible-inventory.yaml).
The hostname is hardcoded in the invnetory because we already 
[require](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/standalone.html#deploying-a-standalone-openstack-node)
that the hostname be set to standalone.localdomain.

#### Network

TripleO standalone needs to configure the 192.168.24.0/24 network
and interface so it doesn't exist yet to use with deployed ceph.
Instead, any VM being deployed by standalone should have its own IP
which can be used by Ceph by passing it as in the following example:

```
openstack overcloud ceph deploy ... --mon-ip 192.168.122.252
```

The above works because of the new
[--mon-ip](https://review.opendev.org/c/openstack/python-tripleoclient/+/822537)
option.

I also pass a [network_data.yaml](network_data.yaml) file
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

I deployed with
`~/templates/environments/cephadm/cephadm-rbd-only.yaml` 
since the RGW spec application task was hanging.

I will look into why RGW isn't working next.
