# Deployed Ceph Demo

In Wallaby and newer it is possible to provision hardware and deploy
Ceph before deploying the overcloud on the same hardware.

## Prerequisites

- As described in [Networking Version 2 (Two)](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/network_v2.html) baremetal instances have been provisioned and had their network configured
- A deployed_metal.yaml file as output by `openstack overcloud node provision -o deployed_metal.yaml ...`

## Overview of command line options

```
openstack overcloud ceph deploy --help
```

## Deploy Ceph using custom stack name

```
openstack overcloud ceph deploy \
          deployed-metal-overcloud-0.yaml \
          -o deployed_ceph.yaml \
          --stack overcloud-0
```

- input: deployed metal file
- output: deployed ceph file

## Examine Cluster During Deployment

- SSH into first controller's IP as identified by `metalsmith list`
- `cephadm shell` and show cluster status

## Examine generated files

In the working directory ($HOME/overcloud-deploy/<stack>)
- tripleo-ansible-inventory.yaml (ansible inventory from network v2)
- generated_ceph_spec.yaml

In the current directory:
- deployed-metal-overcloud-0.yaml
- deployed_ceph.yaml

## Generate your own Ceph Spec from TripleO data (--ceph-spec)

- The end state of the ceph cluster can be definedin a [ceph spec](https://docs.ceph.com/en/latest/cephadm/service-management/#orchestrator-cli-service-spec)
- The [ceph_spec_bootstrap](https://docs.openstack.org/tripleo-ansible/latest/modules/modules-ceph_spec_bootstrap.html) ansible module creates a spec from tripleo yaml files

```
ansible-doc ceph_spec_bootstrap
```

```
ansible localhost -m ceph_spec_bootstrap \
    -a deployed_metalsmith=deployed-metal-overcloud-0.yaml 
```

```
less ~/ceph_spec.yaml
```

You could now edit ceph_spec.yaml as we need to and then run:

```
openstack overcloud ceph deploy \
          deployed-metal-overcloud-0.yaml \
          -o deployed_ceph.yaml \
          --stack overcloud-0 \
          --ceph-spec ~/ceph_spec.yaml
```

## Override which disks are used as OSDs (--osd-spec)

Note the `data_devices` in the spec we generated:

```
grep -B 2 -A 2 data_devices ceph_spec.yaml
```

They default to all. We could edit them in the above directly so we
use a path to a specific block device if we like:

```
$ cat osd_spec.yaml
---
data_devices:
  paths:
    - /dev/vg_ceph/data
$ 
```

We don't have to generate the spec and edit it just to use a different
set of devices as OSDs However. We can run `openstack overcloud ceph
deploy` as usual and get the same effect like this:

```
openstack overcloud ceph deploy \
          deployed-metal-overcloud-0.yaml \
          -o deployed_ceph.yaml \
          --stack overcloud-0 \
          --osd-spec osd_spec.yaml
```


In /usr/share/openstack-tripleo-heat-templates:
- roles_data.yaml

## Override Service Placement (--roles-data)

- Deployed ceph is backwards compatible with composable roles (even
  though it runs before Heat)
- So far we've genereated a spec for 3 controllers, 3 ceph-storage, 1 compute
- Let make a custom roles_data.yaml and see the genereated ceph spec change
  
```
openstack overcloud roles generate Controller CephStorage ComputeHCI > custom_roles.yaml
```

We'll rename ComputeHCI to Compute because we don't have to change the
configuration of the deployed nodes.

```
sed -i s/ComputeHCI/Compute/g custom_roles.yaml
```

```
ansible localhost -m ceph_spec_bootstrap \
 -a "deployed_metalsmith=deployed-metal-overcloud-0.yaml tripleo_roles=custom_roles.yaml"
```

Note that the Compute node now has an OSD label so that its block
devices are used to host OSDs:

```
less ~/ceph_spec.yaml
```

The same thing happens if you deploy like this:

```
openstack overcloud ceph deploy \
          deployed-metal-overcloud-0.yaml \
          -o deployed_ceph.yaml \
          --stack overcloud-0 \
          --roles-data custom_roles.yaml
```

## Container Options (--container-image-prepare)

As per [Container Image Preparation](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/container_image_prepare.html) TripleO provides the following container related features:
- Use Undercloud as Container Registry
- Download different containers from different authenticated registries
- Host Ceph containers along with OpenStack containers

By default `openstack overcloud ceph deploy` will pull the Ceph
container in the default container_image_prepare_defaults.yaml file.

```
egrep "ceph_namespace|ceph_image|ceph_tag" /usr/share/tripleo-common/container-images/container_image_prepare_defaults.yaml
```

This is the exact same behavior as when "deployed ceph" is not used.

The `--container-image-prepare` option overrides which
container_image_prepare_defaults.yaml file is used.

If your Ceph container is in an authenticated registry and you edited
custom_container_image_prepare.yaml to have the valid syntax which
TripleO already supports:

```
  ContainerImageRegistryCredentials:
    quay.io/ceph-ci:
      quay_username: quay_password
```

and then deployed like this:

```
openstack overcloud ceph deploy \
          deployed-metal-overcloud-0.yaml \
          -o deployed_ceph.yaml \
          --stack overcloud-0 \
          --container-image-prepare custom_container_image_prepare.yaml
```

Then the python client will extract the credentials from the file and
direct the tripleo ansible role to bootstrap on the first Ceph monitor
like this:

```
cephadm bootstrap
   --registry-url quay.io/ceph-ci
   --registry-username quay_username
   --registry-password quay_password
   ...
```

The syntax of the container image prepare file can also be ignored and
instead the following command line options may be used instead:

```
  --container-namespace CONTAINER_NAMESPACE
                        e.g. quay.io/ceph
  --container-image CONTAINER_IMAGE
                        e.g. ceph
  --container-tag CONTAINER_TAG
                        e.g. latest
  --registry-url REGISTRY_URL
  --registry-username REGISTRY_USERNAME
  --registry-password REGISTRY_PASSWORD
```

- If a variable above is unused, then it defaults to the ones found in
  the default container_image_prepare_defaults.yaml file.
- In other words, the above options are overrides

## Conclusion

- It is not necessary to use all of these options
- As per the demo we only passed the deployed metal file
- However there are many ways to override the defaults
