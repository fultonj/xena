#!/bin/bash
pushd ~/infrared
virtualenv .venv && source .venv/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools
pip install -e .
popd
