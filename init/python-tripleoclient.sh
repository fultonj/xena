#!/usr/bin/env bash
# Speed up my work on: https://review.opendev.org/#/c/750812

pushd /home/stack/python-tripleoclient
python3 setup.py bdist_egg
sudo python3 setup.py install --verbose
openstack overcloud export ceph --help
popd
