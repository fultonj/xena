# Use tripleo-lab to create an undercloud

I run the following on
[my hypervisor](http://blog.johnlikesopenstack.com/2018/08/pc-for-tripleo-quickstart.html)
which is running centos-stream-8.

## Prepare tripleo-lab

```
 sudo /usr/local/bin/lab-destroy

 git clone git@github.com:cjeanner/tripleo-lab.git

 cd tripleo-lab

 cat inventory.yaml.example | sed s/IP_ADDRESS/127.0.0.1/g > inventory.yaml

 cp ~/xena/tripleo-lab/overrides.yml environments/overrides.yml
 cp ~/xena/tripleo-lab/topology-* environments/

 diff -u builder.yaml ~/xena/tripleo-lab/builder.yaml
 cp ~/xena/tripleo-lab/builder.yaml builder.yaml

 ansible -i inventory.yaml -m ping builder

 ansible-playbook -i inventory.yaml config-host.yaml
```

## Deploy undercloud configured with Metalsmith

```
 ansible-playbook -i inventory.yaml builder.yaml \
    -e @environments/centos-8.yaml \
    -e @environments/stream.yaml \
    -e @environments/podman.yaml \
    -e @environments/vm-centos8.yaml \
    -e @environments/metalsmith.yaml \
    -e @environments/overrides.yml \
    -e @environments/topology-standard.yml
```

The tasks referenced by the tags `-t domains -t baremetal -t vbmc`
(which are inclusive in the above example) will provision the virtual
baremetal servers. See [metalsmith](../metalsmith/).

<!--
## Workarounds

I started getting the following when SSH'ing to a newly installed undercloud.
```
debug1: getpeername failed: Bad file descriptor
...
stdio forwarding failed
```
This started happening 10 Nov 2020 after updating TripleO lab from 9
Oct 2020. It's possibly related to these
https://github.com/cjeanner/tripleo-lab/commit/b874a9865158ad8afb39d4dba4d5b2bbc82c70b8
https://github.com/cjeanner/tripleo-lab/commit/224b7d06e93c5cbc8ece339f81bafd64f806b74b
I don't need that ssh config so I just remove out the undercloud section
```
grep -n '## BEGIN undercloud' .ssh/config
grep -n '## END undercloud' .ssh/config
sed -i -e '1,9d' .ssh/config
```

# https://bugs.launchpad.net/tripleo/+bug/1920215
sed -i s/tripleo_overcloud_node_import_introspect\\:\ false/tripleo_overcloud_node_import_introspect\\:\ true/g ~/.ansible/tripleo-operator-ansible/roles/tripleo_overcloud_node_import/defaults/main.yml

Because tripleo-ansible-operator imports ironic nodes
[without introspection](https://github.com/openstack/tripleo-operator-ansible/blob/master/roles/tripleo_overcloud_node_import/defaults/main.yml#L12)
I sometimes have tripleo-lab
[call it](https://github.com/cjeanner/tripleo-lab/blob/38f3ab758a75063d6fcabe8c24de1719fe2e29b8/roles/overcloud/tasks/baremetal.yaml#L61)
with `tripleo_overcloud_node_import_introspect: true`.

-->

