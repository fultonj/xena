# Xena

Every OpenStack cycle I end up with scripts I revise to make
development easier. This is where I'm storing the scripts for the
Xena cycle.

## How I use

- Use [tripleo-lab overrides](tripleo-lab) to deploy an undercloud
- Run the following on undercloud initialize it for work
```
git clone git@github.com:fultonj/xena.git
pushd xena/init
./git-init.sh alias
./git-init.sh tht
popd
```
- Create a [standard deployment](standard) with Ceph
