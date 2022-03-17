# External Ceph

Deploy an independent Ceph cluster to be used as external Ceph
cluster by TripleO. Deploy an overcloud which uses the external
Ceph cluster.

## Deployment Topology

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
| stack: overcloud |
+------------------+
| oc0-controller-0 |    Controller
| oc0-controller-1 |    Controller
| oc0-controller-2 |    Controller
| oc0-compute-0    |    Compute
+------------------+
```
