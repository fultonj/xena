#!/bin/bash

pushd ~

./directord/.tox/venv/bin/directord bootstrap \
                                    --catalog directord-inventory-catalog.yaml \
                                    --catalog \
                                    directord/tools/directord-dev-bootstrap-zmq-encryption-catalog.yaml \
                                    --key-file ~/.ssh/id_ed25519

popd
