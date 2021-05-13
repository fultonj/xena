# Workaround LP 1925373

[LP 1925373](https://bugs.launchpad.net/tripleo/+bug/1925373)
will break your cephadm deployments becuase the clients
are configured before the servers.

We think this is because deploy-steps.j2 was 
[changed](https://github.com/openstack/tripleo-heat-templates/commit/ef240c1f62a6afb584ef111fbef2f027a474414f)
to use to use list_concat_unique instead of yaql.

This workaround brings in a 
[new implementation](https://review.opendev.org/c/openstack/heat/+/787662/3/heat/engine/hot/functions.py)
of list_concat_unique.

The [heat_patch.sh](heat_patch.sh) uses [prepare.yaml](prepare.yaml)
to build a new container with the patch and 
[heat_container_manage.yml](heat_container_manage.yml) to deploy
the new contianer. It's a variation of a [process](http://blog.johnlikesopenstack.com/2019/07/notes-on-testing-tripleo-common-mistral.html)
I used to follow with paunch which has been 
updated for the [tripleo_container_manage](https://docs.openstack.org/tripleo-ansible/latest/roles/role-tripleo_container_manage.html#debug)
TripleO Ansible module.
