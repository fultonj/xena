#!/bin/bash

pushd ~
sudo dnf -y install git gcc python3-pip python3-devel
git clone https://github.com/directord/directord
pip3 install --user tox
pushd directord
tox -e venv python3 setup.py install_data
popd
popd

