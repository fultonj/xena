#!/bin/bash
export STACK=dcn1

cp -v -f ../dcn0/deploy.sh ${STACK}_deploy.sh
sed s/dcn0/dcn1/g -i ${STACK}_deploy.sh

cp -v -f ../dcn0/glance.yaml .
sed s/dcn0/dcn1/g -i glance.yaml

cp -v -f ../dcn0/overrides.yaml .
sed s/dcn0/dcn1/g -i overrides.yaml

bash ${STACK}_deploy.sh
