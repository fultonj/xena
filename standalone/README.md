# Standalone on VM from virsh

## Scripts for the impatient

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

The above will deploy a [standalone](https://docs.openstack.org/project-deploy-guide/tripleo-docs/wallaby/deployment/standalone.html)
node which uses [deployed ceph](https://docs.openstack.org/project-deploy-guide/tripleo-docs/wallaby/features/deployed_ceph.html). It requires the patches under the [topic ceph_spec](https://review.opendev.org/q/topic:%22ceph_spec%22+(status:open%20OR%20status:merged)).

## Required Files

Because we're not using real block devices we can't use our defualt of
using all available block devices as OSDs. Thus, we create a fake block
device with [disks.sh](disks.sh) and pass [osd_spec.yaml](osd_spec.yaml)
when we create our ceph spec so it uses that fake block device.

Because we're deploying a one-node overcloud and with one disk we need
to configure Ceph so that it doesn't expect to have its usual
redundancy by passing an [initial_ceph.conf](initial_ceph.conf).

## Deploy Ceph in three commands

Because the 192.168.24.0/24 network is not configured until `openstack
tripleo deploy` we need to run ceph on a different network if we're
going to deploy it first. The VM you are using probably already has an
IP address and Ceph can be configured to use it. In my case the IP is
192.168.122.252.

```
    export CEPH_IP=192.168.122.252
```

Create a ceph spec and pass the `--standalone` option. Use the IP
defined earlier and override the default disks to use as OSDs with 
[osd_spec.yaml](osd_spec.yaml).

```
    sudo openstack overcloud ceph spec \
         --standalone \
         --mon-ip $CEPH_IP \
         --osd-spec osd_spec.yaml \
         --output ceph_spec.yaml
```

Create a user cephadm can use to SSH into the overcloud and pass the
generated ceph spec so it knows which hosts to configure the account
on. In a non-standalone scenario this command looks in the default
working directory for the Ansible inventory. After metalsmith is run
this file is created by default. In our case we have it look in the
current directory which has our generic 
[tripleo-ansible-inventory.yaml](tripleo-ansible-inventory.yaml)
for standalone.

```
    sudo openstack overcloud ceph user enable \
         --standalone \
         ceph_spec.yaml \
```

Deploy Ceph passing the same working directory, IP, and ceph spec as
above. Pass an [initial_ceph.conf](initial_ceph.conf) so that Ceph is
configured for a single node deployment and skip the user creation
because it was handled in the previous step. Specify what the output
deployed Ceph file should be called.

```
    sudo openstack overcloud ceph deploy \
          --mon-ip $CEPH_IP \
          --standalone \
          --ceph-spec ceph_spec.yaml \
          --config initial_ceph.conf \
          --skip-user-create \
          --output deployed_ceph.yaml
```
As per the [documented Deployed Ceph Container Options](https://docs.openstack.org/project-deploy-guide/tripleo-docs/wallaby/features/deployed_ceph.html#container-options),
the Ceph container defined in `/usr/share/tripleo-common/container-images/container_image_prepare_defaults.yaml` is used by default but may be overridden.

When you deploy your overcloud use `-e` to pass the generated
`deployed_ceph.yaml` as input to `openstack tripleo deploy`.
