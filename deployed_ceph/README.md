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

- 3 controller
- 1 compute
- 3 ceph-storage

## Client

This is a mock up of how I think the command line which replaces
ceph.sh should look.

```
$ openstack overcloud ceph deploy --help
Deploy Ceph on nodes which have been deployed by Ironic before overcloud deployment

positional arguments:
  <deployed_baremetal.yaml>
                        Environment file output from `openstack overcloud node provision`

  -o OUTPUT, --output OUTPUT
                        The output environment file describing the ceph deployment to
                        path to pass to overcloud deployment

optional arguments:
  -h, --help            show this help message and exit

  --stack STACK         Name or ID of heat stack (default=Env: OVERCLOUD_STACK_NAME)

  --working-dir WORKING_DIR
                        The working directory for the deployment where all
                        input, output, and generated files will be stored.
                        Defaults to "$HOME/overcloud-deploy/<stack>"

  --roles-data          Optional path to roles_data.yaml. If not provided defaults to 
                        /usr/share/openstack/tripleo-heat-templtaes/roles_data.yaml
                        Used to decide which node gets which Ceph mon,mgr,osd service
                        based on the node's role in <deployed_baremetal.yaml>.

  --ceph-spec           Optional path to an existing Ceph spec file. If not provided a
                        spec will be generated automatically based on --roles-data and
                        <deployed_baremetal.yaml>

  --osd-spec            Optional path to an existing OSD spec file. Mutually exclusive
                        with --ceph-spec. If the Ceph spec file is generated automatically
                        then this value defaults to {data_devices: {all: true}} for all
                        service_type osd. Use --osd-spec to override this default if
                        desired.

$
```

So <deployed_baremetal.yaml> would be passed to ansible like this  "-e baremetal_deployed_path"
So --output would be passed to ansible like this  "-e deployed_ceph_tht_path"
