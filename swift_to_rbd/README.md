# Swift to RBD

## Deployment Topology

Deploy an independent Ceph cluster to be used as external Ceph
cluster by TripleO. Deploy an overcloud which uses Swift
as its Glance backend. Upload a cirros image to Glance which
is stored in swift.

Run a stack update on the overcloud which does the following:

- Converts Glance to multistore and adds an additional RBD backend
- Connects Cinder to the External Ceph cluster as an additional backend
- Nova continues to use local ephemeral storage

Finally, we migrate the cirros image from the Swift to the RBD backend.

The virtual hardware will be deployed in the following stacks and
roles.
```
+------------------+
| stack: ceph-e    |
+------------------+
| oc0-ceph-0       |    CephAll Mon/Mgr/OSD
| oc0-ceph-1       |    CephAll Mon/Mgr/OSD
| oc0-ceph-2       |    CephAll Mon/Mgr/OSD
+------------------+

+------------------+
| stack: swift     |
+------------------+
| oc0-controller-0 |    Controller (Swift + Glance + Cinder)
| oc0-controller-1 |    Controller (Swift + Glance + Cinder)
| oc0-controller-2 |    Controller (Swift + Glance + Cinder)
| oc0-compute-0    |    Compute (Nova)
+------------------+
```
