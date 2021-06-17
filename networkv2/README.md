# Configuring the network before deploying the overcloud

This is an example to make sure you can correctly deploy
the network before the overcloud and then deploy a working
overcloud with one controller and one compute.

## What tripleo-lab will do for you

If tripleo-lab was deployed with 
[topology-2-node.yml](../tripleo-lab/topology-2-node.yml),
and the following parameters:
```
metalsmith: true
tripleo_overcloud_node_provision_network_ports: true
```
Then the VIPs, ports, and baremetal nodes will already be created.

The Tags column of `openstack port list --long` will show 
`tripleo_stack_name=overcloud-0` for ports like 
`oc0-compute-0_Storage` and `oc0-controller-0_External`
out of 16 total ports.

The following files will pre-created.

- oc0-role-data.yaml
- vip-data-0.yaml
- oc0-network-data.yaml
- metalsmith-0.yaml

and the last three of the above will be passed as input to three
commands which will in turn create the following three files.

- overcloud-vips-provisioned-0.yaml
- overcloud-networks-provisioned-0.yaml
- overcloud-baremetal-deployed-0.yaml

In other words, the following has been run for you:

```
openstack overcloud network vip provision \
              --stack overcloud-0 \
              --output ~/overcloud-vips-provisioned-0.yaml \
              ~/vip-data-0.yaml

openstack overcloud network provision \
             --output ~/overcloud-networks-provisioned-0.yaml
             ~/oc0-network-data.yaml
             
openstack overcloud node provision \
              --network-ports \
              --stack overcloud-0 \
              --output ~/overcloud-baremetal-deployed-0.yaml \
              ~/metalsmith-0.yaml 
```
If you had installed the undercloud from without tripleo-lab you would
need to do the above yourself.

## Modify tripleo-lab script for network configuration

If you're trying to configure the network before deploying the
overcloud, then the problem with the above is that `openstack
overcloud node provision` command used `--network-ports` instead of
`--network-config`.

Update the script which ran the `node provision` command to make this
substitution and re-run it.
```
sed -i s/network\-ports/network\-config/g ~/tripleo_overcloud_node_provision.sh 
bash ~/tripleo_overcloud_node_provision.sh
```
You should then find the network configured on the deployed nodes.
It is not necessary to unprovision the baremetal nodes when doing the
above.

## Network environemnt files

When `openstack overcloud deploy` is run, pass the generated files
described above as input like this:

```
-r oc0-role-data.yaml
-n oc0-network-data.yaml
-e overcloud-vips-provisioned-0.yaml
-e overcloud-networks-provisioned-0.yaml
-e overcloud-baremetal-deployed-0.yaml
```

tripleo-lab also creates the file `~/overcloud-0-yml/network-env.yaml`
with the necessary `VipSubnetMap`, though the rest of the file is not
necessary, so you could create a smaller environemnt file like this:

```
head -10 network-env.yaml > ~/vip_subnet_map.yaml
```

In place of the following network environment files shipped with THT:

- environments/network-isolation.yaml
- environments/network-environment.yaml

use these network environemnt files as the ports are already deployed
and because tripleo-lab configures a single-nic with VLANs:

- environments/deployed-server-deployed-neutron-ports.yaml
- environments/net-single-nic-with-vlans.yaml

My convention is to store the `tripleo-heat-templates` directory in 
`~/templates` so I update the generated files to reference that path:

```
sed -i \
's|/usr/share/openstack-tripleo-heat-templates|/home/stack/templates|g' \
overcloud-*-*-0.yaml
```

My deploy command looks like this: [deploy.sh](deploy.sh)
