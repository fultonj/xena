# IR Helper Scripts

My co-workers use [IR](https://infrared.readthedocs.io/en/latest) to
test TripleO features which I maintain. This directory has scripts
to help me use IR to help them.

## Hypervisor

The [hypervisor](hypervisor) directory has scripts to be run on the
hypervisor where the `infrared` command is run.

## Undercloud

The [undercloud](undercloud) directory has scripts to be run on the
undercloud deployed by IR.

IR creates scripts found in `/home/stack` like `overcloud_deploy.sh`
but if I want to easily undeploy the overcloud and then deploy only
the baremetal so I can re-run `overcloud_deploy.sh` I use the
[kill.sh](undercloud/kill.sh) and [metal.sh](undercloud/metal.sh)
scripts respectively.
