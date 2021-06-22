# Deployed Ceph POC

Set up an environment to work on the [deployed_ceph](https://review.opendev.org/q/topic:%22deployed_ceph%22+(status:open%20OR%20status:merged)) feature.

## Workarounds

- [get_ceph_container.sh](../workarounds/podman/get_ceph_container.sh)

## Deploy

The [deploy.sh](deploy.sh) script has boolean options to deploy one of
the following:

- METAL
- CEPH
- OVERCLOUD

The second of the above simply calls [ceph.sh](ceph.sh), which will
evolve from a shell script calling ansible to python-tripleoclient
calls.

## Topology

- 1 controller
- 1 compute
- 1 ceph-storage
