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

### Authentication

Though [pre.sh](pre.sh) will install the binaries for you to run
`openstack overcloud ceph deploy` the command will fail because
it cannot authenticate. You can't `source stackrc` as it doesn't
exist. Maybe this command could be changed to `openstack tripleo ceph
deploy` so it works the same was as `openstack tripleo deploy` since
it doesn't really require authentication.

**Workaround** call ansible directly as seen in [ceph.sh](ceph.sh)

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
my own version of it instead of generating it dynamically.

### Network

TripleO standalone needs to configure the 192.168.24.0/24 network
and interface so it doesn't exist for me to use it with deployed
ceph. Originally I was using only the ctlplane when I ran
[clean.sh](clean.sh) and redeployed but on a fresh deploy this creates
a chicken/egg problem.

```
    -e storage_network_name="ctlplane"
    -e storage_mgmt_network_name="ctlplane"
```

**workaround**
Because my VM already has an IP I modified the deployed_ceph deploy
to use that IP instead and then I'll try passing it to the standalone
deployment as if it were a separate storage network.

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

### Hostname

cephadm would fail to apply the spec with this error:

Error EINVAL: Host standalone (192.168.24.2) failed check(s): ['hostname "standalone.localdomain" does not match expected hostname "standalone"']

regardless of if the spec had standalone.localdomain or standalone.

```
if 'expect_hostname' in ctx and ctx.expect_hostname:
    if get_hostname().lower() != ctx.expect_hostname.lower():
        errors.append('hostname "%s" does not match expected hostname "%s"' % (
            get_hostname(), ctx.expect_hostname))
    logger.info('Hostname "%s" matches what is expected.',
                ctx.expect_hostname)
```

Problem was:
- hostname is getting set to "standalone.localdomain"
- ctx.hostname is getting set to "standalone"

TripleO standalone requires you to do this:

```
sudo hostnamectl set-hostname standalone.localdomain
sudo hostnamectl set-hostname standalone.localdomain --transient
```

If I do this then cephadm doesn't have this problem.

```
sudo hostnamectl set-hostname standalone
sudo hostnamectl set-hostname standalone --transient
```

After ceph is deployed I then set it as required by tripleo
standalone.
