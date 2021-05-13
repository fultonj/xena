#!/bin/bash

metalsmith -f value -c State -c "Node Name" list > /tmp/results

TOTAL=$(cat /tmp/results | wc -l)
ERR=$(grep ERROR /tmp/results | wc -l)
ACT=$(grep ACTIVE /tmp/results | wc -l)

echo "Total: $TOTAL | Deployed: $ACT | Failed: $ERR"

I=0
for NAME in $(grep ERROR /tmp/results | awk {'print $1'}); do
    echo "Undeploying $NAME"
    metalsmith undeploy $NAME
    I=$(($I+1))
    echo "Scheduled $I of $ERR"
done
sleep 2
echo "Current state"
metalsmith list
echo "Try to deploy again"
