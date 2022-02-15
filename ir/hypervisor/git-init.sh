#!/bin/bash

git config --global user.email "fulton@redhat.com"
git config --global user.name "John Fulton"
git config --global push.default simple
git config --global gitreview.username fultonj

git review --version
if [ $? -gt 0 ]; then
    echo "installing git-review and tox from pip"
    if [[ $(grep 8 /etc/redhat-release | wc -l) == 1 ]]; then
        if [[ ! -e /usr/bin/python3 ]]; then
            sudo dnf install python3 -y
        fi
    fi
    pip
    if [ $? -gt 0 ]; then
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py
    fi 
    pip install git-review tox
fi

pushd ~
git clone git@github.com:redhat-openstack/infrared.git
pushd infrared
git remote add gerrit ssh://fultonj@review.gerrithub.io:29418/redhat-openstack/infrared.git
git review -s
popd
popd
