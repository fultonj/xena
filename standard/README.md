# Standard Deployment

## Deprecated

This is no longer the "standard" deployment because it does not use
"deployed ceph" as described in the [docs](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_ceph.html).

The "standard internal deployment" should now be considered
[deployed ceph](../deployed_ceph).

## Workarounds

- [get_ceph_container.sh](../workarounds/podman/get_ceph_container.sh)

## Deploy

- [lab_pickup.sh](lab_pickup.sh) (first time only)
- [deploy.sh](deploy.sh)
- [validate.sh](validate.sh)

## Topology

- 3 controller
- 1 compute
- 3 ceph-storage
