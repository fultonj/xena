# Deploy DCN with Storage (Glance with Multiple Ceph Clusters)

## Deployment Topology

The goal is to be able to ask the control-plane Glance to upload an
image to multiple DCN sites so they can be COW fast-booted on that
site. The virtual hardware will be deployed in the following stacks
and roles.

```
+------------------+
| control-plane    |    GlanceBackend: RBD | CephClusterName: central
+------------------+
| oc0-controller-0 |    Controller (Glance + Mon)
| oc0-controller-1 |    Controller (Glance + Mon)
| oc0-controller-2 |    Controller (Glance + Mon)
| oc0-ceph-0       |    ComputeHCI (Nova + OSD)
+------------------+

+------------------+
| dcn0             |    DCN HCI + GlanceBackend: RBD | CephClusterName: dcn0
+------------------+
| oc0-ceph-1       |    DistributedComputeHCI (Glance + Nova + Cinder + OSD)
| oc0-ceph-2       |    DistributedComputeHCIScaleOut (HaProxy + Nova + OSD)
+------------------+

+------------------+
| dcn1             |    DCN quasi-HCI + GlanceBackend: RBD | CephClusterName: dcn1
+------------------+
| oc0-ceph-3       |    CephAll (Mon + OSD)
| oc0-compute-0    |    DistributedCompute (Glance + Nova + Cinder)
+------------------+
```

## Deployment Order

The usual order is:

1. deploy central
2. export central overcloud
3. export central ceph
4. deploy dcn0
5. deploy dcn1
6. export dcn0,dcn1 ceph
7. update central (adding glance and ceph from dcn0 and dcn1)

Because we can now deploy
[metal before overcloud](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/provisioning/baremetal_provision.html)
and
[ceph before overcloud](https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/features/deployed_ceph.html), another order is possible:

1. deploy metal for central,dcn0,dcn1
2. deploy ceph for central,dcn0,dcn1
3. export central ceph
4. export dcn0,dcn1 ceph
5. deploy central overcloud with output of 4 and GlanceMultistoreConfig
6. export central overcloud
7. deploy dcn0 overcloud with output of 3,6 and GlanceMultistoreConfig
8. deploy dcn1 overcloud with output of 3,6 and GlanceMultistoreConfig

After step 5, central glance won't work because it will look for other
glance backends that don't yet exist. In exchange though we can skip
the final stack update. This pattern can be extended for an arbitrary
number of DCN sites in theory, though if DCN sites will be added
later, then the central stack would need an update; i.e. you'd go back
to the old pattern.

## How to deploy it with TripleO

Run the [main.sh](main.sh) script which does the following.

- deploy all virtaul baremetal with [metal.sh](metal.sh) (order is flexible)
```
for STACK in control-plane dcn0 dcn1; do 
  ./metal.sh $STACK;
done
```
- deploy all ceph on with [ceph.sh](ceph.sh) (order is flexible)
```
for STACK in control-plane dcn0 dcn1; do 
  ./ceph.sh $STACK;
done
```

- Create `ceph-export-control-plane.yaml` (`openstack overcloud export ceph -f --stack control-plane`) (requires [835511](https://review.opendev.org/c/openstack/python-tripleoclient/+/835511) )
- Create `ceph-export-2-stacks.yaml` (`openstack overcloud export ceph -f --stack dcn0,dcn1`)
- Deploy control-plane with [control-plane/deploy.sh](control-plane/deploy.sh)
- Copy `control-plane-export.yaml` from $HOME/overlcoud-deploy/$STACK/$STACK-export.yaml ( see [this patch](https://github.com/openstack/python-tripleoclient/commit/80c43280a8a17c6d06b0fe24ab7df48ef29f24e9) )
- Deploy dcn0 with [dcn0/deploy.sh](dcn0/deploy.sh)
- Deploy dcn1 with [dcn1/deploy.sh](dcn1/deploy.sh)

Each deploy script will use [metalsmith](../metalsmith)
to [provision](provision.sh) the nodes for each stack
and the [kill](kill.sh) script will unprovision the nodes.

<!--
## Validations

The scripts below maybe used to: 

- Import an image into the central, dcn0 and dcn1 locations
- Boot an instance and create a volume in the central location
- Boot an instance and create a volume in the dcn0 or dcn1 location
- Verify all necessary Ceph client configurations

### Glance

- Use [use-multistore-glance.sh](validations/use-multistore-glance.sh) to import
  an image into both `default_backend` and `dcn0`
  with [import-multi-stores](https://review.opendev.org/#/c/667132)
  and then copy that image to `dcn1`
  with [copy-existing-image](https://review.opendev.org/#/c/696457).
  A successful example looks
  like [use-multistore-glance.log](validations/use-multistore-glance.log).

### Cinder/Nova on Central

- [use-central.sh](validations/use-central.sh)

### Cinder/Nova on DCN

- [use-dcn.sh](validations/use-dcn.sh)
- [dcn-pet.sh](validations/dcn-pet.sh)
- To test dcn1, update AZ from "dcn0" to "dcn1"

### Ceph

- Verify any DCN node at $IP can use the central ceph cluster
```
scp ../../multiceph/test_ceph_client.sh heat-admin@$IP:/home/heat-admin/
ssh $IP "bash /home/heat-admin/test_ceph_client.sh central"
```

- Verify the control-plane node at $IP can use any DCN ceph cluster
```
scp ../../multiceph/test_ceph_client.sh heat-admin@$IP:/home/heat-admin/
ssh $IP "bash /home/heat-admin/test_ceph_client.sh dcn0"
ssh $IP "bash /home/heat-admin/test_ceph_client.sh dcn1"
```

- Were multiple glance backends configured at central Controller or dcn DistributedComputeHCI at $IP?
```
ssh $IP "sudo tail /var/lib/config-data/puppet-generated/glance_api/etc/glance/glance-api.conf"
```
-->
